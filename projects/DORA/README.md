# DORA — Seasonal SKU Affinity & Slotting Optimization

**Version:** 0.4 (public, generalized edition)  
**Status:** Discovery / data inventory  
**Purpose:** Exploratory design specification. This document contains illustrative fields and synthetic examples only; it does not document any organization's internal systems or operational figures.

## Objective and boundaries

DORA explores relationships between products using historical store demand and warehouse picking activity. It accounts for seasonality, tote compatibility, and slot constraints to recommend feasible slotting improvements for human review.

DORA is **advisory**. The warehouse management system (WMS) remains the system of record for inventory, locations, movements, and execution. The initial proof of concept does not perform automated WMS updates or physical reassignment.

## Discovery principles

- Distinguish **confirmed**, **needs validation**, and **not available** for every dataset and rule.
- Confirm the actual grain and keys before writing affinity calculations.
- Do not infer order-level co-occurrence from store/day/SKU aggregates.
- Do not infer tote compatibility from co-ordering or a single friendly flag.
- Ask one focused discovery question at a time; document adjacent attributes and exceptions.
- Use synthetic or de-identified records in examples and public documentation.

## Initial datasets

The following are *logical example fields*, not claims about actual source tables.

### A. Historical store demand — essential

**Preferred grain:** DC + store + order + SKU line.

| Field | Purpose | Priority |
|---|---|---|
| `DC_ID` | Facility-specific analysis | Required |
| `STORE_ID` | Store-specific patterns | Required |
| `ORDER_DATE` | Time and seasonality | Required |
| `SKU_ID` | Product key | Required |
| `ORDERED_QTY` | Demand quantity | Required |
| `ORDER_ID` | Identify true baskets/orders | Verify |
| `ORDER_LINE_ID` | Deduplicate lines | Useful |
| `ORDER_TYPE`, `QTY_UOM` | Promotions and units | Conditional |
| `SHIP_DATE`, `FULFILLED_QTY` | Compare demand with fulfillment | Useful |

If only daily aggregates exist, the analysis can identify **same-store/same-day co-demand**, not true shared orders or totes.

### B. Picking activity and totes — availability to validate

| Field | Purpose |
|---|---|
| `DC_ID`, `PICK_DATE` | Facility and period |
| `ASSIGNMENT_ID`, `TOTE_ID` | Shared picking workflow |
| `STORE_ID`, `SKU_ID`, `PICKED_QTY` | Picked products and volume |
| `PICK_LOCATION_ID`, `PICK_TIMESTAMP`, `PICK_ZONE` | Sequence, location, process |

Confirm whether assignments include multiple stores or totes, and whether tote identifiers are consistently recorded.

### C. SKU master and compatibility — availability to validate

| Field | Purpose |
|---|---|
| `SKU_ID`, `SKU_DESCRIPTION`, `SKU_STATUS` | Product identity and lifecycle |
| `MAJOR`, `CATEGORY`, `SUBCATEGORY`, `BRAND` | Product hierarchy |
| `CASEPACK`, dimensions, weight | Physical constraints |
| `TOTE_FRIENDLY_FLAG`, `TOTE_COMPATIBILITY_GROUP` | Candidate restrictions |
| `HANDLING_RESTRICTION`, effective dates | Exceptions and historical accuracy |

Validate hierarchy meanings, pairwise compatibility, quantity/sequence restrictions, and effective dating.

### D. Current slots and locations — availability to validate

| Field | Purpose |
|---|---|
| `DC_ID`, `SKU_ID`, `LOCATION_ID` | Placement |
| `LOCATION_TYPE`, `PICK_ZONE` | Pick vs reserve and workflow |
| `AISLE`, `BAY`, `LEVEL` | Spatial relationships |
| `SLOT_CAPACITY`, `CAPACITY_UOM` | Feasibility |
| `CURRENT_ON_HAND`, `LOCATION_RESTRICTIONS`, `EFFECTIVE_DATE` | Utilization, eligibility, history |

## Phased approach

1. **Profile sources:** Confirm source grain, keys, history, refresh cadence, missing periods, lifecycle changes, and data owners.
2. **Generate candidate SKU pairs:** Prefer actual order baskets; compute support, confidence, lift, joint order counts, and absolute joint-pick volume. Generate observed pairs with frequency pruning rather than a dense all-SKU cross join.
3. **Analyze seasonality and compatibility:** Separate stable, seasonal, and event-driven associations. Prefer multiple comparable years when available; account for store coverage, promotions, launches, and stockouts.
4. **Validate operational feasibility:** Check whether co-ordered items actually share assignments, zones, or tote flows. Apply compatibility, capacity, and placement restrictions. Do not claim labor savings without travel and handling measurements.
5. **Review and pilot:** Show recommendation, rationale, confidence, constraints, and source freshness. Route accepted changes through existing WMS processes. Pilot at one facility before broader rollout.

**Out of scope for the initial proof of concept:** production demand forecasting, automated WMS write-back, and automatic physical slot reassignment.

## Preliminary analytical design (not approved)

- **Basket key:** Prefer `DC_ID + ORDER_ID` with store/date validation.
- **Affinity:** Support, directional confidence, lift, joint-order volume; add observed joint-pick frequency when available.
- **Seasonality:** Compare equivalent periods, distinguishing repeated co-demand from individual SKU popularity.
- **Compatibility:** Enforce documented rules; never assume all tote-friendly SKUs are mutually compatible.
- **Simulation:** Start with feasible location candidates. Measure net labor only when travel, replenishment, and relocation data support it.
- **Freshness:** Show source timestamps and revalidate against WMS before physical execution.

## Risks and decisions

1. Daily SKU totals may not reconstruct order baskets.
2. Co-ordered SKUs may not share a picking assignment or tote.
3. Compatibility may be pairwise or dependent on quantities and packing order.
4. Short history may not establish repeatable seasonality.
5. Reduced walking may increase replenishment or relocation effort.
6. Different facilities may require different operational constraints.
7. Recommendations must not override authoritative WMS state.

## Pilot success measures

- Measured change in pick travel or minutes per relevant assignment.
- Net labor impact, including replenishment and relocation.
- Share of recommendations feasible, reviewed, accepted, and implemented.
- Tote-handling exceptions and service/throughput guardrails.

## Discovery questions

| Topic | Ask |
|---|---|
| Product hierarchy | What hierarchy levels and codes exist, and do they change over time? |
| Product attributes | Are dimensions, weight, casepack, handling, and lifecycle attributes available? |
| Tote rules | Is compatibility SKU-level, category-based, pairwise, or sequence-dependent? |
| Orders | Are rows individual order lines or daily aggregates? Is an order ID available? |
| Picking | Which assignment, tote, zone, timestamp, and location identifiers exist? |
| Seasonality | What history, promotional events, and store/region differences are available? |
| Slots | Can SKUs occupy multiple slots? What capacity and location restrictions apply? |
| Quality | Who owns each dataset? What are its refresh, retention, and quality limitations? |

## First discovery request

Identify the historical store-demand dataset and map its actual columns for facility, store, date, SKU, ordered quantity, and order ID if available. Confirm its grain, quantity units, earliest available date, and refresh cadence. Validate with a small de-identified sample before implementing affinity SQL.

---

**Publication note:** This is a generalized public adaptation of an internal working draft. Employer names, operational volumes, internal platform details, and organization-specific assumptions have been intentionally omitted. No real source tables, production records, or performance outcomes are asserted.
