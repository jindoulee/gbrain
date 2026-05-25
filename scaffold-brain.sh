#!/usr/bin/env bash
#
# scaffold-brain.sh — lays down the starter "multifamily sourcing agent" brain
# into your GBrain content repo (default ~/brain), then indexes it.
#
# Each page is tagged `scope: shared` (platform knowledge that benefits every
# customer) or `scope: tenant` (a specific customer's private data that must
# never cross customers). That's the seam you'll later split into GBrain
# "sources" for multi-tenant isolation.
#
# Safe to re-run: existing files are left untouched (your edits win).
#
# Usage:
#   ./scaffold-brain.sh                 # uses ~/brain
#   BRAIN_DIR=~/notes ./scaffold-brain.sh
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
mkdir -p "$BRAIN_DIR"/{concepts,trades,vendors,properties,pm-companies,owners,rfps,projects,inbox,archive}

seed RESOLVER.md <<'MD'
# RESOLVER — filing decision tree for the multifamily sourcing brain

Walk this in order. Every page has exactly one home.

1. A vendor/contractor company → vendors/
2. A specific apartment property → properties/
3. A property-management company (end user) → pm-companies/
4. An ownership group (buyer) → owners/
5. A trade's scope/spec knowledge (how to scope landscaping, asphalt…) → trades/
6. A specific sourcing event (RFP + bids + award) → rfps/
7. Awarded/in-progress work → projects/
8. Product/strategy thinking, frameworks → concepts/
9. Don't know yet → inbox/   |   Dead/old → archive/

Conventions:
- Two layers per page: compiled truth on top, `---`, append-only Timeline below.
- Put queryable facts in YAML frontmatter (type, trades, region, tier, coi_expires…).
- Reference other entities by their exact title so the graph links auto-extract.
- One page per vendor even if they do many trades (MECE = directories, not reality).

Data-isolation seam — tag every page:
- `scope: shared`  → platform knowledge all customers benefit from
                     (trades/, vendors/ directory info, concepts/). Later: a shared source.
- `scope: tenant`  → a specific customer's private data, never crosses customers
                     (properties/, pm-companies/, owners/, rfps/). Later: a per-customer source.
- Vendor *directory* info (exists, trade, region, COI) is shared; a vendor's *bid history
  and pricing* is tenant-private and lives on rfps/ pages, not the vendor page.
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
> vendors, normalize bids apples-to-apples, stack-rank, and produce a cited award
> rationale. Value: drive cost savings, or prove you already have the best deal.

## State
- **ICP:** owner-operators & third-party PMs, 5,000–30,000 units. Sell to ownership; end-user is the PM company. [Source: User, 2026-05-25]
- **PMS:** Yardi, RealPage (read AP/contracts for baseline; write POs back). [Source: User, 2026-05-25]
- **Starting trades:** Landscaping (recurring) + Asphalt Paving (capex). [Source: compiled, 2026-05-25]
- **Approval threshold:** $500+ requires human award. [Source: User, 2026-05-25]
- **Vendor tiers:** marketplace (discovered) → approved (verified) → preferred (proven).
- **Cross-customer learning:** shared layer (scope templates, anonymized benchmarks, vendor
  directory) compounds across customers; private layer (bids, awards, spend) never crosses.
- **Key insight:** value sits at the two ends — scope generation for non-experts, and
  normalizing messy phone/email/PDF bids — not the leveling in the middle.

## Human-in-the-loop (do not automate)
- Capex scope sign-off, physical site walks, award decision, contract/legal terms.

## Open Threads
- Voice agent (inbound/outbound calls) is the riskiest core piece — vendors live on phone.
- Call-recording consent handling (two-party-consent states).
- Cold-start on savings baseline — first cycle establishes it.
- Pricing-intelligence features gated on antitrust counsel — see concepts/pricing-intelligence.

---

## Timeline
- **2026-05-25** | User — Defined concept, ICP, trades, threshold, metric.
- **2026-05-25** | Added cross-customer shared/tenant data model.
MD

seed concepts/pricing-intelligence.md <<'MD'
---
title: Pricing Intelligence — Antitrust Guardrails
type: concept
scope: shared
status: design-constraint
---
# Pricing Intelligence — Antitrust Guardrails

> How we surface price guidance without crossing antitrust lines. Anchored to the
> Nov 2025 DOJ–RealPage settlement: using NONPUBLIC, current competitor data to steer
> pricing is the violation; aggregated/anonymized HISTORICAL market data is defensible.
> Algorithmic pricing is not inherently illegal. [Source: DOJ–RealPage settlement, 2025-11-24]

## Two features, two risk profiles
- **Buyer budget range (PMC-facing) — LOW RISK, build it.** Show an acceptable budget
  range for a scope from aggregated, anonymized market data. Market intelligence,
  pro-competitive. Conditions: aggregated, anonymized, min data-point threshold,
  never "Vendor X bid $Y".
- **Vendor bid meter (vendor-facing) — CONDITIONAL.** A win-confidence meter is OK ONLY
  if powered by aggregated HISTORICAL market data, NOT by the live competing bids on the
  current RFP. The dangerous version tells a vendor "get under $Z to win" where $Z reflects
  rivals' nonpublic bids — that is the RealPage theory.

## The decisive line
| Safe (defensible)                       | Dangerous (RealPage theory)                       |
|-----------------------------------------|---------------------------------------------------|
| aggregated, anonymized, historical      | competitors' nonpublic, current bids on this RFP  |
| "market range for this scope is $X–$Y"  | "beat the other bidders by $Z"                    |
| backward-looking market intelligence    | forward-looking steering on live rival data       |

## Nuances
- "It lowers prices" is NOT a safe harbor — shared signals can create a focal point
  (tacit coordination); the info-exchange theory applies regardless of price direction.
- DOJ withdrew its old info-sharing "safety zones" (2023) — aggregation is necessary but
  no longer an automatic safe harbor; counsel sets the thresholds.
- Supply-side trust: a race-to-the-bottom meter makes vendors disengage. Frame as
  "price to market," not "we'll squeeze you."
- Airline upgrade analogy fails: that's ONE seller; here multiple competing vendors,
  which is exactly where antitrust attaches.

## Open Threads
- MUST get antitrust counsel sign-off before shipping either feature (esp. the meter).
- Counsel to set: minimum aggregation N, data recency window, anonymization method.
- Decide minimum data-point threshold before any benchmark is shown.

---

## Timeline
- **2026-05-25** | Captured antitrust design constraints from RealPage settlement analysis.
MD

seed trades/landscaping.md <<'MD'
---
title: Landscaping
type: trade
scope: shared
category: recurring
---
# Landscaping

> Recurring grounds maintenance. The #1 apples-to-apples trap is scope variance:
> two bids look different only because mowing frequency / mulch / irrigation differ.

## Standard scope line items (force these in every bid form)
- Mowing & edging — frequency (weekly/biweekly), in-season vs off-season
- Bed maintenance & weeding; mulch — cycles/year, depth, coverage
- Shrub/hedge trimming — frequency
- Irrigation checks & repairs — included vs T&M
- Seasonal color — beds, rotations/year
- Tree trimming (under X"); leaf/storm cleanup; trash policing

## Comparability rules
- Normalize to annual cost AND cost per unit.
- Flag exclusions (irrigation repair, storm cleanup) — common hidden-cost gaps.

---

## Timeline
- **2026-05-25** | Seeded from product analysis.
MD

seed trades/asphalt-paving.md <<'MD'
---
title: Asphalt Paving
type: trade
scope: shared
category: capex
---
# Asphalt Paving

> Parking-lot capex. Hard to compare because vendors quote different *methods*
> for the same lot: seal coat vs mill-and-overlay vs full-depth reconstruction.

## Standard scope line items
- Crack fill (linear ft), seal coat (sq ft, # coats)
- Mill & overlay vs full-depth — specify thickness
- Striping & restriping; ADA stalls/ramps (code compliance)
- Patching (sq ft), drainage/ponding fixes

## Comparability rules
- Pin the METHOD before comparing price — a seal-coat bid vs an overlay bid is not apples-to-apples.
- Normalize to cost per sq ft; confirm ADA scope is included.
- Often bundled with Concrete (curbs, sidewalks, ramps).

---

## Timeline
- **2026-05-25** | Seeded as capex pilot trade.
MD

seed trades/concrete.md <<'MD'
---
title: Concrete
type: trade
scope: shared
category: capex
---
# Concrete

> Curbs, sidewalks, ADA ramps, pads. Frequently bundled into parking-lot (Asphalt
> Paving) projects, so a vendor that does both can bid the whole scope.

## Standard scope line items
- Sidewalk/curb replacement (linear ft), ADA ramp rebuilds (code)
- Trip-hazard grinding vs replacement; pads/dumpster enclosures

---

## Timeline
- **2026-05-25** | Seeded (bundles with Asphalt Paving).
MD

seed pm-companies/summit-residential.md <<'MD'
---
title: Summit Residential
type: pm_company
scope: tenant
units: 12000
pms: RealPage
---
# Summit Residential
> Third-party property manager, ~12,000 units. Pilot customer for the sourcing agent. Runs RealPage.
---
## Timeline
- **2026-05-25** | Created as pilot ICP example.
MD

seed properties/maple-court.md <<'MD'
---
title: Maple Court Apartments
type: property
scope: tenant
units: 240
managed_by: Summit Residential
asphalt_sqft: 85000
---
# Maple Court Apartments
> 240-unit property managed by Summit Residential. Needs recurring Landscaping and an upcoming Asphalt Paving resurfacing.
---
## Timeline
- **2026-05-25** | Created.
MD

seed vendors/greenscape-pros.md <<'MD'
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
> Landscaping specialist in Phoenix. Directory info is shared; bid history is tenant-private (lives on rfps/).

## Capabilities (per-trade)
| Trade      | Tier      | Jobs w/ us | Notes |
|------------|-----------|-----------|-------|
| Landscaping| preferred | 9         | reliable, good crews |

---
## Timeline
- **2026-05-25** | Added as preferred landscaping vendor.
MD

seed vendors/evergreen-grounds.md <<'MD'
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
> Landscaping vendor in Phoenix, approved tier. COI expires soon — flag for renewal.

## Capabilities (per-trade)
| Trade      | Tier     | Jobs w/ us | Notes |
|------------|----------|-----------|-------|
| Landscaping| approved | 2         | limited history |

---
## Timeline
- **2026-05-25** | Added as approved landscaping vendor.
MD

seed vendors/apex-contracting.md <<'MD'
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
> General contractor in Phoenix/Tucson. Self-performs Asphalt Paving and Concrete, so it
> can bundle a full parking-lot scope (paving + curbs + ADA ramps) on one award.

## Capabilities (per-trade — track record differs by trade)
| Trade         | Tier      | Jobs w/ us | Notes |
|---------------|-----------|-----------|-------|
| Asphalt Paving| preferred | 11        | strong on overlays |
| Concrete      | approved  | 3         | limited history — watch quality |

---
## Timeline
- **2026-05-25** | Added as multi-trade GC (paving + concrete).
MD

echo "==> Indexing"
gbrain import "$BRAIN_DIR/" --no-embed
gbrain extract links --source db
gbrain extract timeline --source db
gbrain embed --stale
gbrain stats

echo "==> Done. Try:  gb query \"which vendors can bid asphalt paving in Phoenix?\""
