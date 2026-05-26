import type { Artifact, Action, InboundMessage } from "../contracts";

// ── THE CHANNEL-BLIND CORE ────────────────────────────────────────────────
// v0: STUBBED with canned data so the Telegram render + approve interaction
// works end-to-end today. v1: replace the bodies below with a Claude Agent SDK
// session that connects to the gbrain MCP server and runs the run-rfp skill —
// the adapter and contracts do NOT change when you do that.

export async function handleMessage(_msg: InboundMessage): Promise<Artifact> {
  // v1: send _msg into a Claude Agent SDK session (gbrain MCP + run-rfp skill),
  // and return whatever artifact the agent produces.
  return mapleCourtLeaderboard();
}

export async function handleAction(action: Action): Promise<Artifact> {
  switch (action.type) {
    case "approve":
      return award(action.target ?? "evergreen-grounds");
    case "choose_another":
      return chooseAnother();
    case "award_override":
      return award(action.target ?? "", action.reason);
    case "detail":
      return { kind: "text", text: "Full bid tab → (v1: link to the PDF / web view of the normalized table)." };
    case "ask":
      return { kind: "text", text: "Ask me anything about this RFP. (v1: routed to the brain.)" };
    default:
      return { kind: "text", text: "Unknown action." };
  }
}

// ── canned data (v0 only) ──────────────────────────────────────────────────
function mapleCourtLeaderboard(): Artifact {
  return {
    kind: "leaderboard",
    title: "Maple Court · Landscaping re-bid",
    subtitle: "normalized to equal scope",
    items: [
      { rank: 1, vendor: "Evergreen Grounds", price: "$46,400", score: 92, recommended: true },
      { rank: 2, vendor: "GreenScape (incumbent)", price: "$48,000", score: 88 },
      { rank: 3, vendor: "Desert Bloom", price: "n/a", blockedReason: "excluded scope · COI pending" },
    ],
    recommendation: {
      target: "evergreen-grounds",
      summary: "Recommend Evergreen — $1,600/yr (3.3%) under incumbent, equal scope. Contingent on COI renewal.",
    },
    buttons: [
      { label: "✅ Approve Evergreen", action: { type: "approve", rfp: "maple-court-landscaping-2026", target: "evergreen-grounds" } },
      { label: "📄 Full bid tab", action: { type: "detail", rfp: "maple-court-landscaping-2026" } },
      { label: "🔄 Choose another", action: { type: "choose_another", rfp: "maple-court-landscaping-2026" } },
      { label: "💬 Ask a question", action: { type: "ask", rfp: "maple-court-landscaping-2026" } },
    ],
  };
}

function chooseAnother(): Artifact {
  return {
    kind: "text",
    text: "Awarding against the recommendation — pick the vendor:",
    buttons: [
      { label: "GreenScape · $48,000", action: { type: "award_override", rfp: "maple-court-landscaping-2026", target: "greenscape-pros", reason: "manual override of recommendation" } },
      { label: "Desert Bloom · $39,600", action: { type: "ask" }, disabled: true, disabledReason: "No valid COI on file — cannot be awarded until the gate clears." },
    ],
  };
}

function award(target: string, reason?: string): Artifact {
  const name = target === "greenscape-pros" ? "GreenScape Pros" : "Evergreen Grounds";
  const price = target === "greenscape-pros" ? "$48,000/yr" : "$46,400/yr (saves $1,600)";
  const lines = [
    `✅ Awarded: ${name} — ${price}`,
    "⚠ Pending: COI renewal — I've requested it.",
    "Next: sending award + decline notices, then scheduling the start.",
  ];
  if (reason) lines.push(`Override reason logged: ${reason}`);
  return {
    kind: "award",
    title: "Award",
    lines,
    buttons: [{ label: "↩ Undo / re-open", action: { type: "choose_another", rfp: "maple-court-landscaping-2026" } }],
  };
}
