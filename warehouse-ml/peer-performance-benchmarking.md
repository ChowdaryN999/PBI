# Context-Adjusted Peer Performance Benchmarking
## Warehouse machine learning model — implementation and data requirements

**Status:** Proposed design, not a trained or validated model. All examples and field names are illustrative. No employer-specific data, employee records, or production credentials are included.

## 1. Operational problem and decision

Colleagues performing the same work type in the same warehouse section can exhibit materially different performance and throughput. A raw comparison is not necessarily fair: assignments, travel, product mix, equipment, congestion and experience may differ. The purpose is to identify operational conditions and work-method improvement opportunities, not predict an employee's future behavior or automate personnel decisions.

The supervisor's decision is whether to investigate a process barrier, observe a work method, arrange training, or take no action. The model estimates a reference performance under measured comparable conditions. The official engineered labor standard remains unchanged. A model residual is not evidence of effort, intent, misconduct or causation.

## 2. Proposed analytical design

Use assignment-level observations to build a contextual benchmark and aggregate results to work date × warehouse × section × shift × work type. The coaching application displays an eight-week rolling history, with performance percentage and throughput separately by work type. Train on a longer historical period, initially 26–52 weeks if available, to learn workload variation and seasonality; eight weeks is the display window, not necessarily the training window.

Start with a SQL matched-peer benchmark. Only introduce machine learning if it improves accuracy, coverage and actionable operational insights on held-out periods. Candidate models: regularized regression or generalized additive model, then gradient-boosted trees if warranted. Clustering is optional, not a prerequisite.

## 3. Required data extracts

Use CSV or Parquet (preferred for volume and types). Extract from authorized enterprise systems into an approved secure environment, not GitHub. Each file needs a data dictionary, extraction timestamp, time zone, source system, date range, unit definitions and known limitations. Names below are logical contracts, not assumed physical database columns.

### 01_assignment_fact.parquet — required, primary file

Grain: one completed assignment or uniquely identified execution segment. Primary key: warehouse_id + assignment_id + segment_id (or a verified source execution key). Do not duplicate assignment totals if the source contains multiple events.

| Column | Type | Purpose |
|---|---|---|
| warehouse_id | string | Site context and joins |
| assignment_id | string | Assignment identifier |
| segment_id | string | Unique execution segment if needed |
| colleague_key | string | Pseudonymous linkage, not a model feature |
| work_type_id | string | Separate comparable tasks |
| section_id | string | Physical operating area, not just department |
| shift_id | string | Shift context |
| work_date | date | Local operational date, including overnight shift convention |
| assignment_start_ts | timestamp | Sequencing and time-of-day |
| assignment_end_ts | timestamp | Duration and overlap checks |
| actual_direct_minutes | decimal | Official performance denominator |
| earned_standard_minutes | decimal | Official performance numerator |
| handled_units | decimal | Throughput numerator |
| unit_type | string | Cases, pieces, pallets, etc. |
| assignment_status | string | Completed, canceled, reversed, etc. |
| assignment_type | string | Assignment complexity grouping |
| source_updated_ts | timestamp | Deduplication and freshness |
| stores_count | integer | Optional workload mix |
| sku_count | integer | Optional product diversity |
| locations_count | integer | Optional pick density |
| planned_travel_distance | decimal | Optional workload complexity; include distance units |
| planned_units | decimal | Optional pre-execution workload |
| equipment_type | string | Optional resource context |

Illustrative CSV header:
```csv
warehouse_id,assignment_id,segment_id,colleague_key,work_type_id,section_id,shift_id,work_date,assignment_start_ts,assignment_end_ts,actual_direct_minutes,earned_standard_minutes,handled_units,unit_type,assignment_status,assignment_type,source_updated_ts,stores_count,sku_count,locations_count,planned_travel_distance,planned_units,equipment_type
```

### 02_work_type_dim.csv — required

Grain: work type × site or enterprise scope × effective period.

Columns: work_type_id, warehouse_id (or explicit enterprise scope), work_type_name, department, throughput_unit, standard_version, effective_from, effective_to, direct_work_flag, eligible_for_benchmark_flag.

Purpose: ensure Selection, Stocking and other tasks are not compared across incompatible units or engineered standard versions. Validate non-overlapping effective periods.

### 03_section_dim.csv — required

Grain: warehouse × section × effective period.

Columns: warehouse_id, section_id, section_name, department, zone_type, layout_version, effective_from, effective_to. Optional: travel class, temperature zone, equipment requirements.

Purpose: compare physical sections with similar operating characteristics and distinguish layout changes.

### 04_shift_calendar.csv — required

Grain: warehouse × shift × work date (or effective shift definition plus calendar).

Columns: warehouse_id, shift_id, work_date, shift_start_ts, shift_end_ts, timezone, planned_break_minutes, holiday_flag, operational_week_end_date.

Purpose: consistent weekdays, overnight attribution and week boundaries. Use actual roster dates, not assumptions that everyone works Monday–Friday.

### 05_operational_conditions.parquet — strongly recommended

Grain: warehouse × section × time interval (e.g., 15 or 30 minutes).

Columns: warehouse_id, section_id, interval_start_ts, interval_end_ts, active_workload_units, active_colleague_count, equipment_available_count, equipment_downtime_minutes, system_downtime_minutes, replenishment_delay_minutes, congestion_indicator, inventory_exception_count, source_updated_ts.

Purpose: capture external barriers instead of attributing every residual to the individual. Join assignments to overlapping intervals using duration weights or a predeclared start-time rule. Never join every interval and then sum duplicated assignment totals. Missing conditions must be labeled unknown, not zero.

### 06_labor_loss_fact.parquet — diagnostic, recommended

Grain: colleague × assignment or uniquely identified event.

Columns: warehouse_id, colleague_key, assignment_id (nullable if not directly attributable), loss_event_id, event_start_ts, event_end_ts, work_type_id, section_id, loss_category, loss_minutes, reason_code, reason_source, source_updated_ts.

Examples of categories: assignment gap, break-related loss, travel/load/unload loss, equipment delay, system delay. Use official definitions and mutually exclusive allocation rules; do not add overlapping loss measures. If a measure is mathematically derived from actual performance, do not use it to predict that same performance. Keep loss data primarily for diagnostic comparisons, not benchmark features.

### 07_colleague_assignment_history.csv — optional, restricted

Grain: pseudonymous colleague × effective employment or work allocation period.

Columns: colleague_key, warehouse_id, supervisor_key, effective_from, effective_to, training_stage, work_type_certification_status, work_type_experience_band (if approved).

Purpose: effective-dated routing and optional training-stage context. Supervisor identifiers are for access routing only. Exclude identity, names, age, sex, race, disability, medical information, leave reasons and other sensitive attributes from model training. Experience and training features require policy review and bias testing; begin without them unless justified. Keep mapping from pseudonymous keys to employee identity in the authorized application layer only.

### 08_assignment_detail.parquet — optional but useful

Grain: assignment × line or pick event.

Columns: warehouse_id, assignment_id, line_id, anonymized_sku_key, location_key, planned_quantity, completed_quantity, unit_type, planned_sequence, product_handling_class, weight_band, cube_band, planned_travel_distance, exception_code.

Purpose: derive pre-existing assignment complexity features. Aggregate to assignment grain before joining. Exclude fields that encode realized productivity or the target from benchmark features.

### 09_coaching_feedback.csv — phase 2, restricted

Grain: coaching session, with separate child rows for multiple factors or actions.

Columns: coaching_id, colleague_key, supervisor_key, warehouse_id, section_id, work_type_id, coaching_ts, observation_period_start, observation_period_end, contributing_factor_code, action_code, outcome_code, follow_up_date, follow_up_status. Free text, if collected, stays in a restricted operational system and is not a default model input.

Purpose: track whether operational barriers were resolved and whether subsequent performance became more stable. Observational before/after comparisons are not causal evidence; assess interventions using an approved evaluation design, accounting for assignment mix and regression to the mean.

## 4. Relationships and data quality

- Assignment fact many-to-one to effective-dated work type, section and shift dimensions.
- Assignment detail many-to-one to assignment after deduplication; aggregate first.
- Conditions are interval joins; allocate overlap without double-counting.
- Loss events link directly where possible; otherwise use approved time allocation and report unallocated minutes separately.
- Colleague history joins as-of assignment date; avoid current supervisor mapping for historical records.
- Coaching sessions link to subsequent observation windows, not to every historical assignment indiscriminately.

Checks: uniqueness, referential integrity, valid timestamps, no impossible negative minutes, nonzero denominator, consistent units, completed status, missingness by site/section, overlapping shifts or events, standard version changes, reconciliation to official reporting. Never treat absence as zero performance. Flag inadequate coverage and insufficient comparable observations.

## 5. Metrics and analytical grain

For a colleague/work type/day:
- Performance % = 100 × SUM(earned_standard_minutes) / SUM(actual_direct_minutes).
- TPUT = SUM(handled_units) / (SUM(approved_throughput_minutes) / 60). Confirm whether throughput denominator is direct or total productive hours; do not silently assume they are identical.
- Variability range = max eligible daily performance minus min eligible daily performance (percentage points).
- Variability standard deviation and recurring weekday patterns over eight weeks.
- Contextual gap = actual performance % minus expected performance % (percentage points).

Proposed initial eligibility: at least 60 direct minutes per work type/day and sufficient comparable peer observations; validate and tune before deployment. Report number of assignments, peer count, productive minutes and uncertainty. Do not compare throughput across incompatible unit types.

## 6. SQL baseline

Build an assignment-level curated table. Use historical comparable peer groups: same work type, site/section, shift, standard version and workload complexity bands. Use a historical weighted peer mean or robust median, excluding the evaluated colleague from their reference group. Set minimum peer coverage and widen comparison groups only under documented rules. Return insufficient evidence when support is inadequate.

Compare this baseline with the ML model; a simple peer median may be enough.

## 7. ML training specification

Target: official assignment performance percentage (or earned-standard-minutes/actual-direct-minutes ratio). Consider a separate throughput model by work type and unit. An alternative is predicting actual duration from planned assignment characteristics, with expected productivity derived from that estimate.

Features: work type, section, shift, operational calendar, standard version, planned units, assignment size, planned travel, pick density, product handling classes, and independently measured operational conditions. Restrict inputs to factors available at the chosen reference time. Do not use colleague ID, supervisor ID, actual performance, realized throughput, actual duration as a predictor of a duration target, or derived loss metrics that leak the target. Use actual hours only for eligibility or aggregation weights when appropriate.

Train on historical data and validate on later weeks. Use group-aware tests holding out colleagues and, if cross-site transfer is intended, sites. Exclude the evaluated colleague from benchmark training/reference where practical (e.g., grouped out-of-fold predictions). Fit preprocessing on training only. Handle unseen categories and missing features explicitly.

Model candidates: regularized regression; gradient boosting. Weight assignment observations by eligible direct minutes if justified, cap extreme weights, and check sensitivity. Estimate benchmark uncertainty using held-out residual distributions or calibrated prediction intervals. Do not present a point estimate as certainty.

Evaluate MAE in percentage points, weighted MAE, calibration/interval coverage, coverage across work types and sections, stability over time and improvements over SQL baseline. Review error disparities and data quality with authorized governance personnel. Feature attribution (e.g., SHAP) explains model estimates, not causes of an individual's residual.

## 8. Illustrative supervisor output

| Work type | Official actual | Contextual reference | Gap |
|---|---:|---:|---:|
| Selection A | 85% | 83% | +2 pp |
| Selection B | 85% | 107% | -22 pp |

Both observations have the same official performance, but contextual references differ. A negative residual may reflect unmeasured barriers, model error or other differences; it is not evidence of low effort. Show comparable conditions, sample coverage, observed gap minutes and throughput differences as separate diagnostics. When evidence is weak, suppress the benchmark and show the reason.

The supervisor can investigate congestion, equipment, workload mix or training needs, observe working methods, or record that no intervention is appropriate. Do not generate automatic disciplinary recommendations, individual rankings for employment decisions, or changes to pay, schedules, assignments or employment status based on the model.

## 9. Application and operational workflow

Authorized source systems → SQL curated assignment data → baseline and optional validated ML benchmark → restricted diagnostic coaching view → human investigation → structured feedback → evaluation.

The application shows eight-week work-type performance and throughput trends; matched comparison context; data freshness, sample coverage and uncertainty; observed operational barriers; supervisor-selected factors and actions; follow-up dates and outcome review. Access is restricted to authorized roles. Prefer section-level process insights when individual evidence is insufficient.

## 10. Implementation gates

1. Confirm purpose, approvals, official metric definitions, section mapping and authorized data access.
2. Obtain extracts 01–04 and profile data quality; obtain 05–06 to improve context and diagnostics.
3. Reconcile performance and TPUT to existing reports; build SQL peer baseline.
4. Train candidate models only if data coverage is adequate; evaluate on held-out periods and groups.
5. Conduct a limited, approved pilot focused on process barriers and voluntary coaching, with supervisor feedback and colleague correction mechanisms.
6. Compare against baseline on actionable findings, resolved barriers, performance stability, error and fairness; avoid attributing causal savings without credible evaluation.
7. Release only with approval, access controls, audit logs, documented model versions, drift checks, retention rules and rollback procedures.

## 11. First extract request

Start with the assignment fact, work-type dimension, section dimension and shift calendar for one pilot site and one work type. Request 26 weeks if available, including assignment timestamps, standard and actual minutes, units, physical section and planned assignment characteristics. Provide column names and types, five to ten synthetic or approved de-identified sample rows, row counts by week, and the official performance and throughput formulas. Do not send raw employee records to public repositories or unapproved services.

**Success criterion:** a more reliable, operationally actionable comparison of like-for-like work, not simply a more accurate prediction of individual employee performance.
