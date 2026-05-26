---
name: run-rfp
description: Run a multifamily sourcing RFP end-to-end for a recurring service or capital project — generate scope, find eligible (gated) vendors, normalize bids apples-to-apples, score and stack-rank per the bid scoring policy, and draft a cited award rationale with human-approval gates. Use when the user asks to run/start/create an RFP, solicit bids, or source a vendor for a trade at a property.
---

# Run an RFP (multifamily sourcing)

You are running a competitive sourcing event end-to-end and recording it in the GBrain brain
via the gbrain MCP tools. Reproduce the quality and structure of `deals/maple-court-landscaping-2026`.

## Before you start — read these brain pages
- `concepts/scoring-policy` — gates -> weighted -> conversation -> human model. AUTHORITATIVE.
- `concepts/pricing-intelligence` — antitrust guardrails (never expose one vendor's bid to another).
- `concepts/<trade>` (e.g. `concepts/landscaping`) — standard scope line items + comparability rules.
- `deals/maple-court-landscaping-2026` — the page structure to mirror.

## Inputs (ask the user for anything missing)
property (slug under entities/), trade, target start/due dates, any property-specific scope notes.

## Steps
1. **Scope + itemized bid form.** From `concepts/<trade>` draft the scope AND a structured bid form.
   The bid form MUST break out every high-variance or optional item as its OWN line (asphalt: seal coat,
   crack fill, ADA ramps, striping; landscaping: irrigation repair, seasonal color, mulch cycles). If a
   cost can be excluded by a vendor, it MUST be a separate line — itemization is what makes apples-to-apples
   possible later. Require each bidder to mark every line included / excluded / alternate. Confirm with the user.

2. **Eligible vendors — gates first.** Query the brain (search + graph-query) for vendors whose `trades`
   include the trade AND whose `region` matches the property's market. Apply GATES: valid COI (not
   pending/expired), required license, minimum tier. Aim for >= 3 eligible bidders. If fewer qualify,
   tell the user and offer vendor discovery — never pad the field with unqualified vendors.

3. **Create the RFP page.** `deals/<property>-<trade>-<year>` (type: rfp, scope: tenant, status: open).
   Link the property, trade, scoring-policy, and each invited vendor; include the itemized bid form.

4. **Collect + normalize bids — NEVER fabricate a plug.** Record each bid against the itemized form.
   For any line a bidder excluded, plug a price in this PRIORITY ORDER:
   - (a) ask that vendor to price the missing line (best — a real number);
   - (b) else use the median of the SAME line item from the other bidders;
   - (c) else the anonymized benchmark for that line.
   If none of (a)-(c) gives a basis, do NOT invent a number — mark the bid "not comparable: clarification
   required" and flag it for vendor follow-up. Always show each plug's SOURCE and tag it [estimate].
   Present an as-quoted vs normalized table. A low sticker with excluded scope is NOT the low bid.

5. **Gate check at bid time (not just at invite).** If a bid arrives from an unvetted/discovered vendor,
   capture it as a marketplace-tier vendor page and auto-request its COI. A bidder that fails a gate
   (no valid COI/license) is recorded and surfaced but is NOT awardable until the gate clears — do not
   rank it as if eligible. State this explicitly.

6. **Conversation signal.** Capture call/email conduct as cited notes (`[Source: call, YYYY-MM-DD]`),
   keeping a FACT (binding commitment -> pull into the normalized bid) separate from a Read (subjective ->
   feeds reliability/quality only). Write to the RFP page AND each vendor's timeline.

7. **Score — derive every number from brain data; never score on vibes.** Use `concepts/scoring-policy`
   weights (recurring = price-heavy; capex = quality/risk-heavy). For each survivor, score each criterion
   0-100 from EVIDENCE and cite the source:
   - **Price:** normalized cost indexed to the field (lowest at-parity = 100, scale the rest down).
   - **Track record:** vendor tier + jobs-with-us + timeline outcomes (preferred/many = high; approved/few
     = mid; marketplace/zero = low, and mark low-confidence).
   - **Reliability:** from THIS RFP's conversation signal (responsiveness, commitments kept).
   - **Quality:** from past job ratings/notes; if none exist, mark "insufficient data" — do not invent.
   - **Risk (capex):** COI/financial/safety; mostly a gate, residual as score.
   Show the per-criterion scores, the weights applied, and the data source for each. Where a criterion has
   no data, say so and LOWER the overall confidence rather than guessing. Then stack-rank.

8. **Recommend + rationale.** Cited recommendation that INCLUDES explicit "why not the cheapest" and
   "why not the incumbent." Compute savings vs the baseline/incumbent if known. State confidence + any data gaps.

9. **Human gates — never auto-award.** Flag scope sign-off (a licensed engineer for structural capex), the
   award decision (any award over $500), and any COI-renewal contingency. Present a one-screen decision:
   recommendation + rationale + the single approval question. Keep status: open ("awaiting approval") until
   the human approves; only then set status: awarded and write the final award note.

10. **Persist + close the loop.** Save all pages via the gbrain tools and link them. After award: draft
    win/decline notices, trigger the winner's COI/compliance step, and (when the job completes) record the
    OUTCOME on the winning vendor's page so its reliability/track-record compounds for future RFPs. Then
    run `gbrain embed --stale` (one writer at a time on PGLite).

## Iron rules
- >= 3 real, gated bids. The competitive process IS the product (savings OR documented best-deal assurance).
- Always NORMALIZE before comparing, and NEVER fabricate a plug price — derive it (a/b/c) or flag for clarification.
- Every score derives from cited brain data; mark and de-confidence anything you can't evidence.
- NEVER reveal one vendor's bid or price to another vendor (antitrust). Benchmarks are aggregated/anonymized only.
- The human owns the award and the weights. You apply, explain, and recommend — you NEVER auto-award.
- The RFP and its bids are tenant-private (deals/, scope: tenant). Vendor directory info is shared.
