# telegram-agent (v0)

A tiny Telegram front door for the sourcing agent. v0 proves the **render +
approve interaction** with a *canned* leaderboard; v1 swaps the stubbed core
for the real brain (gbrain MCP + the run-rfp skill).

## Architecture (the future-proofing)
```
Telegram  ──>  src/adapters/telegram.ts   (ONLY Telegram-aware code)
                       │  neutral InboundMessage / Action
                       v
               src/core/agent.ts           (channel-blind; v0 canned, v1 = real brain)
                       │  neutral Artifact (LeaderboardCard / AwardCard / text)
                       v
               src/adapters/telegram.ts    renders per-channel
```
- Add WhatsApp/Slack/SMS later = a new file in `src/adapters/`. Core + `contracts.ts` never change.
- Visual artifacts are abstract in the core; each adapter renders them (Telegram text/PNG + inline keyboard; WhatsApp image + 3 buttons; etc.).

## Setup
1. In Telegram, message **@BotFather** → `/newbot` → follow prompts → copy the **token**.
2. From this folder:
   ```bash
   export TELEGRAM_BOT_TOKEN="paste-the-token"
   bun install
   bun start
   ```
3. Open your bot in Telegram and send any message. You'll get the Maple Court
   leaderboard with tap buttons:
   - **Approve Evergreen** → award card.
   - **Choose another** → GreenScape is selectable (logs an override reason);
     Desert Bloom is shown **blocked** (no COI — tapping explains why).

## Roadmap
- **v1** — replace the canned bodies in `src/core/agent.ts` with a Claude Agent
  SDK session that connects to the gbrain MCP server and runs `run-rfp`.
- **v1.5** — render the leaderboard as a PNG image (universal across channels).
- **v2** — add `src/adapters/whatsapp.ts` (field + vendor reach) against the same contract.

> Note: for always-on / multi-client use, move the brain to Postgres (PGLite is
> single-process). Don't run gbrain CLI writes while this bot holds the brain.
