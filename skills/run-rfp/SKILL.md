---
name: run-rfp
description: Run a multifamily sourcing RFP end-to-end for a recurring service or capital project — generate scope, find eligible (gated) vendors, normalize bids apples-to-apples, score and stack-rank per the bid scoring policy, and draft a cited award rationale with human-approval gates. Use when the user asks to run/start/create an RFP, solicit bids, or source a vendor for a trade at a property.
---

# Run an RFP (multifamily sourcing)

You are running a competitive sourcing event end-to-end and recording it in the GBrain
brain via the gbrain MCP tools. Reproduce the quality and structure of the worked example
`deals/maple-court-landscaping-2026`.

## Before you start — read these brain pages
- `concepts/scoring-policy` — the gates -> weighted -> conversation -> human model. AUTHORITATIVE.
- `concepts/pricing-intelligence` — antitrust guardrails (never expose one vendor's bid to another).
- `concepts/<trade>` (e.g. `concepts/landscaping`) — standard scope line items + comparability rules.
- `deals/maple-court-landscaping-2026` — the page structure to mirror.

## Inputs (ask the user for anything missing)
property (slug under entities/), trade, target start/due dates, any property-specific scope notes.

## Steps
1. **Scope.** From `concepts/<trade>`, draft the scope + a bid form that FORCES line-item pricing and
   explicit inclusions/exclusions (this is what makes bids comparable later). Confirm scope with the user.
2. **Eligible vendors — gates first.** Query the brain (search + graph-query) for vendors whose `trades`
   include the trade AND whose `region` matches the property's market. Apply GATES: valid COI (flag
   pending/expired), required license, minimum tier. Aim for >= 3 eligible bidders. If fewer qualify,
   tell the user and offer vendor discovery — do NOT pad the field with unqualified vendors.
3. **Create the RFP page.** Write `deals/<property>-<trade>-<year>` (type: rfp, scope: tenant,
   status: open). Link the property, the trade, scoring-policy, and each invited vendor. List invited vendors.
4. **Collect + normalize bids.** As bids arrive (from the user or captured calls/emails), record each.
   Then NORMALIZE to EQUAL scope — plug missing line items so every bid covers the same work (the
   apples-to-apples step). Show as-quoted vs normalized in a table. A low sticker with excluded scope
   is NOT the low bid.
5. **Conversation signal.** Capture call/email conduct as cited notes (`[Source: call, YYYY-MM-DD]`),
   separating a FACT (binding commitment -> pull into the normalized bid) from a Read (subjective ->
   feeds reliability/quality only). Write these to the RFP page AND each vendor's timeline.
6. **Score.** Apply `concepts/scoring-policy`: gates already applied; now weighted score using the
   trade-appropriate weights (recurring = price-heavy; capex = quality/risk-heavy); then fold in the
   conversation signal. Stack-rank.
7. **Recommend + rationale.** Draft a cited award recommendation that INCLUDES an explicit "why not the
   cheapest" and "why not the incumbent." Compute savings vs the baseline/incumbent if known.
8. **Human gates.** Flag what needs human sign-off: scope sign-off (a licensed engineer for structural
   capex), the award decision (any award over $500), and any COI-renewal contingency. Do NOT mark the
   RFP awarded until the human approves — keep status: open with an "awaiting approval" note.
9. **Persist.** Save all pages via the gbrain tools, link everything, then run `gbrain embed --stale`
   (or tell the user to) so new pages are searchable. One writer at a time on PGLite — if the CLI is
   needed, it must not run concurrently with another gbrain process.

## Iron rules
- >= 3 real, gated bids. The competitive process IS the product (savings OR a documented best-deal assurance).
- Always NORMALIZE before comparing. Always CITE every claim and bid.
- NEVER reveal one vendor's bid or price to another vendor (antitrust). Benchmarks are aggregated/anonymized only.
- The human owns the award decision and the weights. You apply and explain; you NEVER auto-award.
- The RFP and its bids are tenant-private (deals/, scope: tenant). Vendor directory info is shared.
