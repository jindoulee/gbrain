import { Bot, InlineKeyboard } from "grammy";
import type { Artifact, Action, ActionButton } from "../contracts";
import { handleMessage, handleAction } from "../core/agent";

// ── TELEGRAM ADAPTER ──────────────────────────────────────────────────────
// The ONLY Telegram-aware code. Translates Telegram <-> the neutral contract.
// Swapping in WhatsApp/Slack later means writing a sibling adapter; the core
// (core/agent.ts) and contracts.ts stay exactly as they are.

// Telegram caps callback_data at 64 bytes, so we stash actions in a small map
// and pass only a short key. (v0: in-memory; resets on restart — fine for now.)
const actionStore = new Map<string, Action>();
let seq = 0;
const encode = (a: Action): string => {
  const key = `a${seq++}`;
  actionStore.set(key, a);
  return key;
};

function keyboard(buttons?: ActionButton[]): InlineKeyboard | undefined {
  if (!buttons?.length) return undefined;
  const kb = new InlineKeyboard();
  for (const b of buttons) {
    const label = b.disabled ? `${b.label} ✋` : b.label;
    const action: Action = b.disabled ? { type: "ask", reason: b.disabledReason } : b.action;
    kb.text(label, encode(action)).row();
  }
  return kb;
}

// v0 renders the leaderboard as a plain-text card. v1.5 upgrade: render a PNG
// and send it as a photo (universal across channels) — the contract is ready.
function renderText(a: Artifact): string {
  if (a.kind === "text") return a.text;
  if (a.kind === "award") return [a.title, "", ...a.lines].join("\n");
  const rows = a.items.map((i) => {
    const medal = i.rank === 1 ? "🥇" : i.rank === 2 ? "🥈" : "🥉";
    const star = i.recommended ? "  ★ recommended" : "";
    const tail = i.blockedReason ? `  —  ${i.blockedReason}` : `  ${i.price}${i.score ? `  (${i.score})` : ""}`;
    return `${medal} ${i.vendor}${tail}${star}`;
  });
  return [a.title, a.subtitle ?? "", "", ...rows, "", a.recommendation.summary].join("\n");
}

async function send(ctx: any, a: Artifact) {
  await ctx.reply(renderText(a), { reply_markup: keyboard("buttons" in a ? a.buttons : undefined) });
}

export function startTelegram(token: string) {
  const bot = new Bot(token);

  bot.on("message:text", async (ctx) => {
    const artifact = await handleMessage({
      channel: "telegram",
      userId: String(ctx.from?.id ?? ""),
      text: ctx.message.text,
    });
    await send(ctx, artifact);
  });

  bot.on("callback_query:data", async (ctx) => {
    const action = actionStore.get(ctx.callbackQuery.data);
    // Disabled buttons (e.g. a gated vendor) just show a toast, no new message.
    if (action?.type === "ask" && action.reason) {
      await ctx.answerCallbackQuery({ text: action.reason, show_alert: true });
      return;
    }
    await ctx.answerCallbackQuery();
    if (!action) return;
    const artifact = await handleAction(action);
    await send(ctx, artifact);
  });

  bot.catch((err) => console.error("bot error:", err));
  console.log("Telegram bot starting (long polling). Message it in Telegram.");
  bot.start();
}
