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
2. From this folder (the bot now answers from the brain, so it needs the Anthropic key too):
   ```bash
   export TELEGRAM_BOT_TOKEN="paste-the-token"
   export ANTHROPIC_API_KEY="sk-ant-..."   # the bot's own (pay-per-token)
   bun install
   bun start
   ```
3. Open your bot in Telegram and ask it something about your brain, e.g.
   *"why didn't we pick the cheapest bid at Maple Court?"* — it retrieves the
   relevant pages and answers with citations.

> One writer at a time: this bot shells out to `gbrain`, so don't run Claude
> Code against the same PGLite brain while the bot is running.

## Roadmap
- **v1a (done)** — `src/core/agent.ts` retrieves from gbrain + synthesizes a
  cited answer via the Claude Messages API. Read-only, brain-grounded.
- **v1b (next)** — swap the core for a Claude Agent SDK session so it can RUN
  the run-rfp skill and WRITE back to the brain (the approve buttons then
  persist awards). Adapter + contracts unchanged.
- **v1.5** — render the leaderboard as a PNG image (universal across channels).
- **v2** — add `src/adapters/whatsapp.ts` (field + vendor reach) against the same contract.

> Note: for always-on / multi-client use, move the brain to Postgres (PGLite is
> single-process). Don't run gbrain CLI writes while this bot holds the brain.
