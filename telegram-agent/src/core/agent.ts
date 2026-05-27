import Anthropic from "@anthropic-ai/sdk";
import { spawn } from "node:child_process";
import type { Artifact, Action, InboundMessage } from "../contracts";

// ── v1a CORE — answers from the REAL brain ────────────────────────────────
// Pipeline: retrieve top chunks from gbrain (CLI) → synthesize a cited answer
// with Claude (Messages API). This makes the bot genuinely brain-grounded.
//
// v1b will replace this with the Claude Agent SDK so the agent can RUN the
// run-rfp skill and WRITE back to the brain (not just read). The adapter and
// contracts don't change when that happens.

const anthropic = new Anthropic(); // reads ANTHROPIC_API_KEY from the environment

const SYSTEM =
  "You are the sourcing assistant for a multifamily procurement team. " +
  "Answer using ONLY the brain excerpts provided in the user message. " +
  "Cite the page slug (e.g. concepts/scoring-policy) behind each claim. " +
  "If the excerpts don't contain the answer, say so plainly — never invent. " +
  "Be concise and practical.";

// Retrieve top chunks from the brain via the gbrain CLI, working around the
// known exit-hang (correct output prints, then the process spins forever):
// capture stdout, detect when it goes idle, then kill the process.
function retrieve(queryText: string, timeoutMs = 15000): Promise<string> {
  return new Promise((resolve) => {
    let out = "";
    const p = spawn("gbrain", ["search", queryText], { stdio: ["ignore", "pipe", "pipe"] });
    p.stdout.on("data", (d) => (out += d.toString()));
    let lastLen = -1;
    let idle = 0;
    const finish = () => {
      clearInterval(poll);
      clearTimeout(hard);
      try { p.kill("SIGKILL"); } catch {}
      resolve(out.trim().slice(0, 4000));
    };
    const poll = setInterval(() => {
      if (out.length > 0 && out.length === lastLen) {
        if (++idle >= 4) finish(); // ~2s with no new output = result is in
      } else {
        idle = 0;
      }
      lastLen = out.length;
    }, 500);
    const hard = setTimeout(finish, timeoutMs);
    p.on("error", finish);
  });
}

export async function handleMessage(msg: InboundMessage): Promise<Artifact> {
  const context = await retrieve(msg.text);
  const res = await anthropic.messages.create({
    model: "claude-opus-4-7",
    max_tokens: 1024,
    // cache_control is set correctly, but this short prompt is below Opus 4.7's
    // 4096-token cache minimum, so it won't actually cache until v1b inlines the
    // skill + policy into a large system prefix. Then caching pays off.
    system: [{ type: "text", text: SYSTEM, cache_control: { type: "ephemeral" } }],
    messages: [
      { role: "user", content: `Brain excerpts:\n${context || "(none found)"}\n\nQuestion: ${msg.text}` },
    ],
  });
  const text = res.content
    .filter((b) => b.type === "text")
    .map((b) => (b as Anthropic.TextBlock).text)
    .join("\n")
    .trim();
  return { kind: "text", text: text || "I couldn't find anything relevant in the brain for that." };
}

export async function handleAction(action: Action): Promise<Artifact> {
  // v1b: route approvals through the Agent SDK so they WRITE the award to the
  // brain (set status, write the cited rationale). For now, acknowledge.
  return {
    kind: "text",
    text: `(${action.type} received — write-back lands in v1b, when the Agent SDK can update the brain.)`,
  };
}
