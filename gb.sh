#!/usr/bin/env sh
#
# gb.sh — a thin wrapper around the `gbrain` CLI.
#
# Why this exists:
#   gbrain's read commands (query / get / search) print correct output but then
#   fail to release the event loop, so the process never exits on its own (the
#   shell just hangs after the result). This wrapper runs gbrain in the
#   background, returns the moment output stops arriving, and kills the lingering
#   process — so `gb query "..."` feels instant. Write commands (import, embed,
#   list, doctor) exit fine on their own; you can call `gbrain` directly for those.
#
# Install (zsh — macOS default):
#   echo 'source ~/path/to/gb.sh' >> ~/.zshrc && exec zsh
#
# Usage:
#   gb query "what's open with Alice?"
#   gb get people/alice
#   gb search "acme"

gb() {
  # Silence background-job notifications ([2] 12345 / "+ terminated") where supported.
  if [ -n "$ZSH_VERSION" ]; then
    setopt local_options no_monitor 2>/dev/null
  fi

  out=$(mktemp)
  gbrain "$@" >"$out" 2>&1 &
  pid=$!

  last=-1
  idle=0
  spins=0
  while kill -0 "$pid" 2>/dev/null; do
    cur=$(wc -c < "$out")
    if [ "$cur" -gt 0 ] && [ "$cur" -eq "$last" ]; then
      idle=$((idle + 1))
      [ "$idle" -ge 4 ] && break          # ~2.8s with no new output = result is in
    else
      idle=0
    fi
    last=$cur
    spins=$((spins + 1))
    [ "$spins" -ge 240 ] && break          # hard ceiling ~168s, just in case
    sleep 0.7
  done

  kill "$pid" 2>/dev/null
  sleep 0.2
  kill -9 "$pid" 2>/dev/null

  cat "$out"
  rm -f "$out"
  unset out pid last idle spins cur
}
