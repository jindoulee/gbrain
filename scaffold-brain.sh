#!/usr/bin/env bash
#
# scaffold-brain.sh — starter "multifamily sourcing agent" brain for GBrain.
#
# IMPORTANT design note (learned the hard way):
# GBrain's auto-graph only recognizes a FIXED set of "entity directories"
# (people, companies, concepts, deals, entities, projects, meetings, …) and
# only links via EXPLICIT markdown links `[Title](dir/slug)` — not bare prose
# and not custom directories. So we map the domain onto GBrain's native dirs:
#
#   vendors / PM companies / owners  -> companies/   (distinguished by `type:`)
#   trades + strategy notes          -> concepts/
#   properties                       -> entities/
#   RFP / sourcing events            -> deals/
#   awarded work                     -> projects/
#
# Each page is tagged `scope: shared` (platform knowledge) or `scope: tenant`
# (a customer's private data) — the seam you later split into GBrain sources.
#
# Safe to re-run: existing files are left untouched.
#
# Usage:  ./scaffold-brain.sh        (BRAIN_DIR defaults to ~/brain)
#
set -euo pipefail
BRAIN_DIR="${BRAIN_DIR:-$HOME/brain}"

seed() {  # seed <relative-path> — writes heredoc only if the file doesn't exist
  local p="$BRAIN_DIR/$1"
  if [ -f "$p" ]; then echo "skip (exists): $1"; cat >/dev/null; return; fi
  mkdir -p "$(dirname "$p")"
  cat >"$p"
  echo "wrote: $1"
}

echo "==> Scaffolding sourcing-agent brain into $BRAIN_DIR"
mkdir -p "$BRAIN_DIR"
( cd "$BRAIN_DIR" && [ -d .git ] || git init -q )
mkdir -p "$BRAIN_DIR"/{concepts,companies,entities,deals,projects,inbox,archive}

seed RESOLVER.md <<'MD'
# RESOLVER — filing decision tree for the multifamily sourcing brain

GBrain's graph only links pages in its recognized entity directories, via
explicit markdown links. So we use GBrain-native dirs and a `type:` field to
keep domain meaning:

| Domain thing                    | Directory   | `type:`         |
|---------------------------------|-------------|-----------------|
| Vendor / contractor             | companies/  | vendor          |
| Property-management company     | companies/  | pm_company      |
| Ownership group                 | companies/  | owner_group     |
| Trade scope knowledge           | concepts/   | trade           |
| Product / strategy / policy     | concepts/   | concept         |
| Apartment property              | entities/   | property        |
| RFP / sourcing event            | deals/      | rfp             |
| Awarded / in-progress work      | projects/   | project         |

Rules:
- Two layers per page: compiled truth on top, `---`, append-only Timeline below.
- Queryable facts go in YAML frontmatter (type, trades, region, tier, coi_expires…).
- TO CREATE A GRAPH EDGE: write an explicit markdown link `[Title](dir/slug)` in
  the prose. Bare mentions and non-recognized dirs do NOT link.
- One page per vendor even if it does many trades (MECE = directories, not reality).

Data-isolation seam — tag every page:
- `scope: shared`  → platform knowledge all customers benefit from (concepts/, vendor
                     directory info in companies/). Later: a shared GBrain source.
- `scope: tenant`  → a customer's private data, never crosses customers (their
                     properties, PM company, RFPs, awards). Later: a per-customer source.
- A vendor's *directory* info is shared; its *bid history/pricing* is tenant-private
  and lives on the deals/ (RFP) page, not the vendor page.
MD

seed concepts/sourcing-agent.md <<'MD'
---
title: Multifamily Sourcing Agent
type: concept
scope: shared
status: thesis
---
# Multifamily Sourcing Agent

> An agent that helps non-expert on-site multifamily teams run real competitive
> sourcing for recurring services and capital projects: generate scope, invite
> vendors, normalize bids apples-to-apples, stack-rank, produce a cited award
> rationale. Value: drive cost savings, or prove you already have the best deal.

## State
- **ICP:** owner-operators & third-party PMs, 5,000–30,000 units. Sell to ownership; end-user is the PM company. [Source: User, 2026-05-25]
- **PMS:** Yardi, RealPage (read AP/contracts for baseline; write POs back). [Source: User, 2026-05-25]
- **Starting trades:** [Landscaping](concepts/landscaping) (recurring) + [Asphalt Paving](concepts/asphalt-paving) (capex). [Source: compiled, 2026-05-25]
- **Approval threshold:** $500+ requires human award. [Source: User, 2026-05-25]
- **Vendor tiers:** marketplace (discovered) → approved (verified) → preferred (proven).
- **Cross-customer learning:** shared layer (scope templates, anonymized benchmarks,
  vendor directory) compounds across customers; private layer (bids, awards) never crosses.
- **Pricing features** are gated on antitrust review — see [Pricing Intelligence](concepts/pricing-intelligence).

## Human-in-the-loop (do not automate)
- Capex scope sign-off, physical site walks, award decision, contract/legal terms.

## Open Threads
- Voice agent (inbound/outbound calls) is the riskiest core piece — vendors live on phone.
- Call-recording consent (two-party-consent states).
- Cold-start on savings baseline — first cycle establishes it.

---

## Timeline
- **2026-05-25** | User — Defined concept, ICP, trades, threshold, metric.
MD

seed concepts/pricing-intelligence.md <<'MD'
---
title: Pricing Intelligence — Antitrust Guardrails
type: concept
scope: shared
status: design-constraint
---
# Pricing Intelligence — Antitrust Guardrails

> How we surface price guidance without crossing antitrust lines, for the
> [Multifamily Sourcing Agent](concepts/sourcing-agent). Anchored to the Nov 2025
> DOJ–RealPage settlement: using NONPUBLIC, current competitor data to steer pricing
> is the violation; aggregated/anonymized HISTORICAL market data is defensible.
> Algorithmic pricing is not inherently illegal. [Source: DOJ–RealPage settlement, 2025-11-24]

## Two features, two risk profiles
- **Buyer budget range (PMC-facing) — LOW RISK, build it.** Acceptable budget range
  for a scope from aggregated, anonymized market data. Conditions: aggregated,
  anonymized, min data-point threshold, never "Vendor X bid $Y".
- **Vendor bid meter (vendor-facing) — CONDITIONAL.** OK only if powered by aggregated
  HISTORICAL market data, NOT the live competing bids on the current RFP. The dangerous
  version tells a vendor "get under $Z to win" where $Z reflects rivals' nonpublic bids.

## The decisive line
| Safe (defensible)                       | Dangerous (RealPage theory)                       |
|-----------------------------------------|---------------------------------------------------|
| aggregated, anonymized, historical      | competitors' nonpublic, current bids on this RFP  |
| "market range for this scope is $X–$Y"  | "beat the other bidders by $Z"                    |

## Nuances
- "It lowers prices" is NOT a safe harbor — shared signals can create a focal point.
- DOJ withdrew its info-sharing "safety zones" (2023) — counsel sets thresholds.
- Supply-side trust: a race-to-the-bottom meter makes vendors disengage.

## Open Threads
- MUST get antitrust counsel sign-off before shipping either feature (esp. the meter).
- Counsel to set minimum aggregation N, recency window, anonymization method.

---

## Timeline
- **2026-05-25** | Captured antitrust constraints from RealPage settlement analysis.
MD

seed concepts/landscaping.md <<'MD'
---
title: Landscaping
type: trade
scope: shared
category: recurring
---
# Landscaping

> Recurring grounds maintenance. #1 apples-to-apples trap is scope variance:
> two bids differ only because mowing frequency / mulch / irrigation differ.

## Standard scope line items (force these in every bid form)
- Mowing & edging — frequency, in-season vs off-season
- Bed maintenance & weeding; mulch — cycles/year, depth, coverage
- Shrub/hedge trimming; irrigation checks (included vs T&M)
- Seasonal color; tree trimming; leaf/storm cleanup; trash policing

## Comparability rules
- Normalize to annual cost AND cost per unit.
- Flag exclusions (irrigation repair, storm cleanup) — common hidden-cost gaps.

---

## Timeline
- **2026-05-25** | Seeded from product analysis.
MD

seed concepts/asphalt-paving.md <<'MD'
---
title: Asphalt Paving
type: trade
scope: shared
category: capex
---
# Asphalt Paving

> Parking-lot capex. Hard to compare because vendors quote different *methods*:
> seal coat vs mill-and-overlay vs full-depth reconstruction. Often bundled with
> [Concrete](concepts/concrete) (curbs, ADA ramps).

## Standard scope line items
- Crack fill, seal coat (sq ft, # coats)
- Mill & overlay vs full-depth — specify thickness
- Striping & restriping; ADA stalls/ramps (code); patching; drainage

## Comparability rules
- Pin the METHOD before comparing price (seal-coat vs overlay are not apples-to-apples).
- Normalize to cost per sq ft; confirm ADA scope included.

---

## Timeline
- **2026-05-25** | Seeded as capex pilot trade.
MD

seed concepts/concrete.md <<'MD'
---
title: Concrete
type: trade
scope: shared
category: capex
---
# Concrete

> Curbs, sidewalks, ADA ramps, pads. Frequently bundled into [Asphalt Paving](concepts/asphalt-paving)
> parking-lot projects, so a vendor that does both can bid the whole scope.

## Standard scope line items
- Sidewalk/curb replacement, ADA ramp rebuilds (code)
- Trip-hazard grinding vs replacement; pads/dumpster enclosures

---

## Timeline
- **2026-05-25** | Seeded (bundles with Asphalt Paving).
MD

seed companies/summit-residential.md <<'MD'
---
title: Summit Residential
type: pm_company
scope: tenant
units: 12000
pms: RealPage
---
# Summit Residential
> Third-party property manager, ~12,000 units. Pilot customer. Runs RealPage.
> Manages [Maple Court Apartments](entities/maple-court).
---
## Timeline
- **2026-05-25** | Created as pilot ICP example.
MD

seed entities/maple-court.md <<'MD'
---
title: Maple Court Apartments
type: property
scope: tenant
units: 240
asphalt_sqft: 85000
---
# Maple Court Apartments
> 240-unit property managed by [Summit Residential](companies/summit-residential).
> Needs recurring [Landscaping](concepts/landscaping) and an upcoming
> [Asphalt Paving](concepts/asphalt-paving) resurfacing.
---
## Timeline
- **2026-05-25** | Created.
MD

seed companies/greenscape-pros.md <<'MD'
---
title: GreenScape Pros
type: vendor
scope: shared
vendor_type: specialist
trades: [Landscaping]
region: [Phoenix AZ]
coi_expires: 2026-11-30
---
# GreenScape Pros
> Landscaping specialist in Phoenix. Self-performs [Landscaping](concepts/landscaping).
> Directory info is shared; bid history is tenant-private (lives on deals/ pages).

## Capabilities (per-trade)
| Trade      | Tier      | Jobs w/ us | Notes |
|------------|-----------|-----------|-------|
| Landscaping| preferred | 9         | reliable, good crews |

---
## Timeline
- **2026-05-25** | Added as preferred landscaping vendor.
MD

seed companies/evergreen-grounds.md <<'MD'
---
title: Evergreen Grounds
type: vendor
scope: shared
vendor_type: specialist
trades: [Landscaping]
region: [Phoenix AZ]
coi_expires: 2026-07-15
---
# Evergreen Grounds
> Landscaping vendor in Phoenix, approved tier. Self-performs [Landscaping](concepts/landscaping).
> COI expires soon — flag for renewal.

## Capabilities (per-trade)
| Trade      | Tier     | Jobs w/ us | Notes |
|------------|----------|-----------|-------|
| Landscaping| approved | 2         | limited history |

---
## Timeline
- **2026-05-25** | Added as approved landscaping vendor.
MD

seed companies/apex-contracting.md <<'MD'
---
title: Apex Contracting
type: vendor
scope: shared
vendor_type: general_contractor
trades: [Asphalt Paving, Concrete]
region: [Phoenix AZ, Tucson AZ]
coi_expires: 2026-09-30
---
# Apex Contracting
> General contractor in Phoenix/Tucson. Self-performs [Asphalt Paving](concepts/asphalt-paving)
> and [Concrete](concepts/concrete), so it can bundle a full parking-lot scope
> (paving + curbs + ADA ramps) on one award.

## Capabilities (per-trade — track record differs by trade)
| Trade         | Tier      | Jobs w/ us | Notes |
|---------------|-----------|-----------|-------|
| Asphalt Paving| preferred | 11        | strong on overlays |
| Concrete      | approved  | 3         | limited history — watch quality |

---
## Timeline
- **2026-05-25** | Added as multi-trade GC (paving + concrete).
MD

seed companies/desert-bloom-landscaping.md <<'MD'
---
title: Desert Bloom Landscaping
type: vendor
scope: shared
vendor_type: specialist
trades: [Landscaping]
region: [Phoenix AZ]
coi_expires: pending
---
# Desert Bloom Landscaping
> Marketplace (discovered) landscaping vendor in Phoenix. Self-performs [Landscaping](concepts/landscaping).
> Not yet verified — COI pending. Surfaced during the Maple Court re-bid.

## Capabilities (per-trade)
| Trade      | Tier        | Jobs w/ us | Notes |
|------------|-------------|-----------|-------|
| Landscaping| marketplace | 0         | unproven; bid biweekly mowing, no seasonal color |

---
## Timeline
- **2026-05-25** | Discovered + invited to the Maple Court landscaping RFP.
MD

seed deals/maple-court-landscaping-2026.md <<'MD'
---
title: RFP — Maple Court Landscaping 2026
type: rfp
scope: tenant
status: awarded
trade: Landscaping
issued: 2026-05-20
due: 2026-05-28
baseline_annual: 48000
award_annual: 46400
annual_savings: 1600
awarded_to: Evergreen Grounds
---
# RFP — Maple Court Landscaping 2026

> Annual landscaping re-bid for [Maple Court Apartments](entities/maple-court) (240 units, Phoenix).
> Three competitive bids. Awarded to [Evergreen Grounds](companies/evergreen-grounds) at $46,400/yr
> normalized — $1,600/yr (3.3%) below the incumbent baseline — contingent on COI renewal.
> Lesson: the lowest sticker ([Desert Bloom](companies/desert-bloom-landscaping), $39,600) was the
> MOST expensive once normalized to equal scope. [Source: compiled, 2026-05-25]

## Scope
Per [Landscaping](concepts/landscaping) standard scope: weekly in-season mowing/edging, 4 mulch
cycles, bed weeding, shrub trimming, irrigation checks + repair, seasonal color (2 rotations),
storm cleanup. Bid form forced line-item pricing + explicit inclusions/exclusions.

## Bids — as quoted vs normalized to EQUAL scope (the apples-to-apples step)
| Vendor | Tier | As-quoted | Scope gaps plugged | Normalized | $/unit/yr |
|--------|------|-----------|--------------------|-----------|-----------|
| [GreenScape Pros](companies/greenscape-pros) (incumbent) | preferred | $48,000 | — full scope | **$48,000** | $200 |
| [Evergreen Grounds](companies/evergreen-grounds) | approved | $41,400 | +irrigation repair $3,000, +2 mulch cycles $2,000 | **$46,400** | $193 |
| [Desert Bloom](companies/desert-bloom-landscaping) | marketplace | $39,600 | +weekly mowing $4,800, +seasonal color $1,800, +irrigation $3,000 | **$49,200** | $205 |

## Stack rank (price 40 / scope 25 / track record 20 / schedule-quality 15)
1. **Evergreen Grounds** — lowest at-parity cost, approved tier, full scope after clarification.
2. **GreenScape Pros** — proven incumbent, full scope, but $1,600/yr more (the assurance option).
3. **Desert Bloom** — lowest sticker but highest normalized cost, unproven (0 jobs), COI pending.

## Award + rationale
Awarded to **[Evergreen Grounds](companies/evergreen-grounds)** at $46,400/yr.
- **Savings:** $1,600/yr (3.3%) vs the $48,000 incumbent baseline.
- **Why not Desert Bloom (lowest sticker):** normalized to equal scope it is the MOST expensive,
  it is unproven, and its COI is pending. Lowest price is not the best deal.
- **Why not stay with GreenScape:** proven, but $1,600/yr more for the same scope.
- **Contingency:** conditional on Evergreen renewing its COI (expires 2026-07-15) before start.

## Human-in-the-loop gates (award > $500 threshold)
- Scope sign-off: PM (recurring service, no engineer needed).
- Award decision + the savings: regional manager approved.
- COI renewal: compliance loop auto-requests from Evergreen.

## Benchmark note (antitrust-safe)
The $193–$205/unit/yr range feeds the AGGREGATED, ANONYMIZED benchmark in the shared layer;
individual bids stay tenant-private. See [Pricing Intelligence](concepts/pricing-intelligence).

## Open Threads
- Evergreen COI renewal before contract start (blocking).
- Evergreen written acceptance of plugged scope at $46,400.

---

## Timeline
- **2026-05-20** | Issued RFP to GreenScape (incumbent), Evergreen, Desert Bloom (discovered).
- **2026-05-22** | Site walk completed with all three bidders.
- **2026-05-26** | Bids in. Desert Bloom excluded irrigation + seasonal color; Evergreen excluded irrigation repair.
- **2026-05-27** | Leveled to equal scope — Desert Bloom normalized highest despite lowest sticker.
- **2026-05-28** | Recommended Evergreen; regional manager approved; award contingent on COI renewal.
MD

seed concepts/scoring-policy.md <<'MD'
---
title: Bid Scoring Policy
type: concept
scope: shared
status: design-constraint
---
# Bid Scoring Policy

> How the [Multifamily Sourcing Agent](concepts/sourcing-agent) decides which bid is best.
> Four stages: gates -> weighted score -> conversation signal -> human award. Everything is
> cited; the human owns the weights and the final call; the agent applies and explains.

## Stage 1 — Gates (pass/fail, never traded off)
Eliminate any bid that fails: valid COI/insurance, required trade license, minimum vendor tier,
disqualifying financial/lien/safety red flags. A low price NEVER buys off a failed gate.

## Stage 2 — Weighted score (on survivors); weights depend on the trade
Recurring/commoditized trades weight price; high-stakes capex weights quality + risk.

| Criterion | [Landscaping](concepts/landscaping) (recurring) | High-stakes capex (e.g. roofing) |
|-----------|------------------------------------------------|----------------------------------|
| Price (normalized) | 45% | 25% |
| Track record + quality | 30% | 35% |
| Reliability / schedule | 15% | 10% |
| Risk / financial stability | gate | 20% |
| Warranty / terms | 10% | 10% |

Price is always the NORMALIZED (apples-to-apples) figure — see the Maple Court RFP for the
plug-the-gaps method. [Asphalt Paving](concepts/asphalt-paving) sits between the two columns.

## Stage 3 — Conversation signal (calls + emails influence the decision)
Vendor conduct during the bid predicts job performance. It enters three ways:
- **Binds commitments into the bid** — verbal "we'll include X" / "we start June 1" are captured
  and pulled into the normalized comparison.
- **Feeds the weighted criteria** — responsiveness, preparedness, competence = reliability/quality.
- **Surfaces risk flags** — evasive on COI, over-promising, can't explain method.

Rules: capture -> attribute -> timestamp -> CITE every note. Separate FACT (a binding commitment)
from INTERPRETATION (a subjective read). The agent surfaces; the human owns the soft judgment.
Notes live as sourced timeline entries on the vendor AND RFP pages, so a vendor's conduct
compounds into a cross-RFP reliability track record.

## Stage 4 — Human award
The agent recommends with a cited rationale (including why-not-the-cheapest). A human approves any
award over the $500 threshold. Weights are policy (human-owned); scoring is mechanical (agent).

## Where weights are set — default-and-override cascade (most specific wins)
platform default (per trade) -> corporate/owner policy -> PMC -> region -> property -> this RFP.
Ship trade defaults so customers start non-blank; each level overrides only what it cares about.

## Cold start
No performance history day one -> lean on price + gates + tier + external reviews/references;
the track-record weight grows as job outcomes accrue on vendor pages.

## Antitrust note
Weighting and benchmarks stay transparent and use aggregated/anonymized data — see
[Pricing Intelligence](concepts/pricing-intelligence).

## Open Threads
- Don't over-build config: ship trade defaults + one corporate override, add finer levels on demand.
- Conversation capture depends on the voice/email layer (vendors live on phone) — riskiest core piece.

---

## Timeline
- **2026-05-25** | Defined the gates -> weighted -> conversation -> human model and the override cascade.
MD

echo "==> Indexing"
gbrain import "$BRAIN_DIR/" --no-embed
gbrain extract links --source db
gbrain extract timeline --source db
gbrain embed --stale
gbrain stats

echo "==> Done. Try:  gb graph-query companies/apex-contracting --depth 2"
