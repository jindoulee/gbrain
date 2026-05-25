#!/usr/bin/env bash
#
# setup-gbrain.sh — one-shot installer for GBrain (https://github.com/garrytan/gbrain)
#
# Installs Bun + gbrain, creates a PGLite brain with vector search, seeds a
# content repo, and verifies the install end-to-end. Designed to run on a host
# with open outbound network (macOS or Linux) — NOT inside a restricted sandbox,
# where the embedding hosts are blocked by the egress allowlist.
#
# Usage:
#   ./setup-gbrain.sh                 # interactive (prompts for any missing keys)
#   GBRAIN_SEARCH_MODE=tokenmax ./setup-gbrain.sh
#   BRAIN_DIR=~/notes ./setup-gbrain.sh
#   INSTALL_AUTOPILOT=1 ./setup-gbrain.sh
#
# Configuration (all optional; env-driven so it can run unattended in CI):
#   OPENAI_API_KEY        embeddings + chat models        (sk-proj-… / sk-…)
#   ZEROENTROPY_API_KEY   embeddings + reranker (default) (ze-…)
#   ANTHROPIC_API_KEY     query expansion (improves search) (sk-ant-…)
#   GBRAIN_SEARCH_MODE    conservative | balanced | tokenmax   (default: balanced)
#   BRAIN_DIR             where your markdown content lives      (default: ~/brain)
#   GBRAIN_ENV_FILE       file the keys are persisted to         (default: ~/.gbrain.env)
#   INSTALL_AUTOPILOT     1 to install the 24/7 dream-cycle daemon (default: off)
#
set -euo pipefail

# ── pretty output ────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; DIM=$'\033[2m'; RST=$'\033[0m'
else
  BOLD=""; RED=""; GRN=""; YEL=""; DIM=""; RST=""
fi
step() { printf '\n%s==> %s%s\n' "$BOLD" "$1" "$RST"; }
ok()   { printf '%s  ok  %s %s\n' "$GRN" "$RST" "$1"; }
warn() { printf '%s warn %s %s\n' "$YEL" "$RST" "$1"; }
die()  { printf '%s fail %s %s\n' "$RED" "$RST" "$1" >&2; exit 1; }

SEARCH_MODE="${GBRAIN_SEARCH_MODE:-balanced}"
BRAIN_DIR="${BRAIN_DIR:-$HOME/brain}"
ENV_FILE="${GBRAIN_ENV_FILE:-$HOME/.gbrain.env}"

case "$SEARCH_MODE" in
  conservative|balanced|tokenmax) ;;
  *) die "GBRAIN_SEARCH_MODE must be conservative|balanced|tokenmax (got '$SEARCH_MODE')" ;;
esac

# ── 1. Bun ─────────────────────────────────────────────────────────────────────
step "Checking Bun"
if ! command -v bun >/dev/null 2>&1; then
  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
  export PATH="$BUN_INSTALL/bin:$PATH"
  if ! command -v bun >/dev/null 2>&1; then
    warn "Bun not found — installing from bun.sh"
    curl -fsSL https://bun.sh/install | bash
    export PATH="$BUN_INSTALL/bin:$PATH"
  fi
fi
command -v bun >/dev/null 2>&1 || die "Bun install failed; install it manually: https://bun.sh"
ok "bun $(bun --version)"

# ── 2. gbrain ──────────────────────────────────────────────────────────────────
step "Installing gbrain (global)"
bun install -g github:garrytan/gbrain
export PATH="${BUN_INSTALL:-$HOME/.bun}/bin:$PATH"
command -v gbrain >/dev/null 2>&1 || die "gbrain not on PATH after install; open a new shell and re-run"
ok "gbrain $(gbrain --version 2>/dev/null || echo '?')"

# Bun occasionally blocks the postinstall hook on global installs (issue #218),
# so schema migrations don't run. Recover deterministically.
if gbrain doctor --json 2>/dev/null | grep -q '"schema_version":0'; then
  warn "schema_version 0 — running migrations (gbrain issue #218)"
  gbrain apply-migrations --yes
fi

# ── 3. API keys ────────────────────────────────────────────────────────────────
step "API keys"
prompt_secret() { # $1=var name, $2=label, $3=hint
  local cur="${!1:-}"
  [ -n "$cur" ] && { ok "$2 taken from environment"; return; }
  if [ -t 0 ]; then
    printf '  %s (%s), blank to skip: ' "$2" "$3"
    read -rs val; echo
    [ -n "$val" ] && export "$1=$val"
  fi
}
prompt_secret OPENAI_API_KEY    "OPENAI_API_KEY"    "sk-…  embeddings + chat"
prompt_secret ZEROENTROPY_API_KEY "ZEROENTROPY_API_KEY" "ze-…  default embeddings"
prompt_secret ANTHROPIC_API_KEY "ANTHROPIC_API_KEY" "sk-ant-…  query expansion"

# Persist keys so future shells, cron, and the daemon can read them.
umask 077
: > "$ENV_FILE"
[ -n "${OPENAI_API_KEY:-}" ]      && printf 'export OPENAI_API_KEY=%q\n' "$OPENAI_API_KEY"           >> "$ENV_FILE"
[ -n "${ZEROENTROPY_API_KEY:-}" ] && printf 'export ZEROENTROPY_API_KEY=%q\n' "$ZEROENTROPY_API_KEY" >> "$ENV_FILE"
[ -n "${ANTHROPIC_API_KEY:-}" ]   && printf 'export ANTHROPIC_API_KEY=%q\n' "$ANTHROPIC_API_KEY"     >> "$ENV_FILE"
printf 'export PATH="%s/bin:$PATH"\n' "${BUN_INSTALL:-$HOME/.bun}"                                   >> "$ENV_FILE"
chmod 600 "$ENV_FILE"
ok "keys saved to $ENV_FILE (chmod 600)"

# Source it from the shell profile (idempotent).
for prof in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$prof" ] || continue
  grep -qF "$ENV_FILE" "$prof" || printf '\n# gbrain\n[ -f "%s" ] && . "%s"\n' "$ENV_FILE" "$ENV_FILE" >> "$prof"
done

# ── 4. Pick an embedding provider ───────────────────────────────────────────────
step "Selecting embedding provider"
if [ -n "${ZEROENTROPY_API_KEY:-}" ]; then
  EMBEDDING_MODEL="zeroentropyai:zembed-1"
elif [ -n "${OPENAI_API_KEY:-}" ]; then
  EMBEDDING_MODEL="openai:text-embedding-3-large"
else
  EMBEDDING_MODEL=""
  warn "No embedding key provided — installing keyword-only (no vector search)."
  warn "Add one later: gbrain config set embedding_model <provider:model> && gbrain embed --stale"
fi
[ -n "$EMBEDDING_MODEL" ] && ok "embedding model: $EMBEDDING_MODEL"

# ── 5. Create the brain ─────────────────────────────────────────────────────────
step "Creating brain (PGLite — no server)"
if [ -n "$EMBEDDING_MODEL" ]; then
  gbrain init --pglite --embedding-model "$EMBEDDING_MODEL"
else
  gbrain init --pglite --no-embedding
fi
gbrain config set search.mode "$SEARCH_MODE"
ok "search mode: $SEARCH_MODE"

# ── 6. Content repo ─────────────────────────────────────────────────────────────
step "Content repo at $BRAIN_DIR"
mkdir -p "$BRAIN_DIR"
[ -d "$BRAIN_DIR/.git" ] || ( cd "$BRAIN_DIR" && git init -q )
ok "$BRAIN_DIR ready (put your markdown here, MECE dirs: people/ companies/ concepts/ …)"

# ── 7. Import + embed ───────────────────────────────────────────────────────────
step "Importing $BRAIN_DIR"
gbrain import "$BRAIN_DIR/" --no-embed
if [ -n "$EMBEDDING_MODEL" ]; then
  step "Generating embeddings (needs reachable provider)"
  gbrain embed --stale
fi

# ── 8. Verify — the two things that break in a restricted sandbox ───────────────
step "Verifying"

# 8a. embedding provider reachable?
if [ -n "$EMBEDDING_MODEL" ]; then
  probe="$(gbrain doctor --json 2>/dev/null | tr ',' '\n' | grep -A1 'embedding_provider' | tr '\n' ' ' || true)"
  if printf '%s' "$probe" | grep -qiE 'forbidden|host_not_allowed|not in allowlist'; then
    warn "embedding_provider probe was blocked — your network is filtering the embedding host."
    warn "Vector search won't work here. Run on a host with open egress to '${EMBEDDING_MODEL%%:*}'."
  else
    ok "embedding_provider reachable"
  fi
fi

# 8b. do read commands actually EXIT? (sandbox bug: correct output, never exits)
if gbrain list 2>/dev/null | head -1 | grep -q .; then
  slug="$(gbrain list 2>/dev/null | head -1 | awk '{print $1}')"
  if [ -n "$slug" ]; then
    if timeout 20 gbrain get "$slug" >/dev/null 2>&1; then
      ok "read path exits cleanly (gbrain get '$slug')"
    else
      rc=$?
      if [ "$rc" -eq 124 ]; then
        warn "gbrain get did not exit within 20s — the event-loop hang seen in restricted"
        warn "sandboxes. On a normal host this should return instantly. Wrap calls in"
        warn "'timeout' + output capture if it persists."
      fi
    fi
  fi
fi

# ── 9. Optional daemon ──────────────────────────────────────────────────────────
if [ "${INSTALL_AUTOPILOT:-0}" = "1" ]; then
  step "Installing autopilot (dream cycle + live sync)"
  gbrain autopilot --install
  ok "autopilot installed"
fi

# ── done ─────────────────────────────────────────────────────────────────────
step "Done"
cat <<EOF
${GRN}GBrain is set up.${RST}

  brain content : $BRAIN_DIR
  search mode   : $SEARCH_MODE
  embeddings    : ${EMBEDDING_MODEL:-(keyword-only)}
  keys/env      : $ENV_FILE  (sourced from your shell profile)

Try it:
  ${DIM}gbrain query "what are the key themes across my notes?"${RST}
  ${DIM}gbrain search "<keyword>"${RST}
  ${DIM}gbrain doctor${RST}

Next:
  • Drop your markdown into $BRAIN_DIR, then: gbrain sync --repo "$BRAIN_DIR" && gbrain embed --stale
  • Scaffold the 43 bundled skills into your agent workspace:
      cd /path/to/agent/workspace && gbrain skillpack scaffold --all
  • 24/7 maintenance (if not already): gbrain autopilot --install
EOF
