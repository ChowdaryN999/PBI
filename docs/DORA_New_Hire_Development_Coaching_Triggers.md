# DORA | New Hire Development — Coaching Triggers

**Status:** Proposed Version 1 · **Scope:** Coaching trigger design (not yet implemented)

## Purpose

DORA (Digital Operational Reporting & Applications) should turn new-hire operational data into actionable supervisor follow-ups: **who needs attention, what pattern was detected, what to investigate, and whether an intervention helped**. It is not intended to duplicate a Power BI dashboard.

The application should evaluate the 13-week new-hire productivity ramp, identify meaningful patterns, and consolidate related triggers into a single colleague-level coaching recommendation. Supervisors should record an action once; DORA should monitor subsequent performance automatically.

## Proposed coaching triggers

| # | Trigger | Proposed detection logic | Evaluation | Recommended supervisor response |
|---|---|---|---|---|
| 1 | **Performance Below Expected Ramp** | Actual weekly productivity is below the applicable ramp target for **two consecutive completed weeks**. | Weekly | Review assignments and observe work process; identify barriers to meeting ramp expectations. |
| 2 | **Performance Stalled** | Weekly productivity improvement is **less than 3 percentage points** for **two consecutive week-to-week comparisons**, while productivity remains below the ramp target. | Weekly | Review why development has plateaued and whether training or support needs to change. |
| 3 | **Attendance Concerns** | Proposed: **2 or more qualifying unplanned absences within 30 days**, or repeated tardiness under an HR-approved rule. | Daily, if appropriate data exists | Conduct a private check-in and follow established attendance procedures; do not treat protected leave as a coaching violation. |
| 4 | **Performance Declining** | Weekly productivity drops by **at least 10 percentage points** versus the preceding comparable completed week. | Weekly | Investigate changes in work type, assignments, equipment, or other conditions. |
| 5 | **Recurring TML** | TML exceeds an **agreed threshold** on at least **3 worked days in the current week**. Threshold not yet defined. | Daily | Examine primary loss categories and distinguish operational constraints from controllable behaviors. |
| 6 | **Picker Accuracy** | **At least 2 validated picking errors** in the current workweek. | Daily | Review error details and provide targeted process observation or coaching. |
| 7 | **Coaching Not Effective** | Following a recorded coaching action, productivity remains below ramp target without **meaningful improvement across 2 complete worked weeks**. Meaningful improvement threshold not yet defined. | Weekly | Reassess intervention and determine whether additional support is needed. |
| 8 | **Performance Volatility** | Within the **current workweek**, highest valid daily productivity minus lowest valid daily productivity is **at least 20 percentage points**, with **at least 3 worked days**. | Daily during the week | Compare daily assignments, work types, TML, and operating conditions to understand variation. |

**All numeric thresholds are preliminary design proposals**, not approved operational policy. Validate against historical data, business expectations, and data availability before activation.

## Key calculations

### Weekly productivity

```text
Weekly Productivity (%) = SUM(STDONLY) / SUM(ACTONLY) * 100
```

Use the applicable week of the 13-week ramp to retrieve the expected productivity target. Exclude invalid or zero-denominator records, and apply agreed minimum-worked-time and completeness rules.

### Trigger 1 — Below expected ramp

```text
Trigger = (ActualProductivity[week - 1] < RampTarget[week - 1])
      AND (ActualProductivity[week]     < RampTarget[week])
```

Example: Week 4 target 70%, actual 68%; Week 5 target 75%, actual 69%. Trigger after the second completed below-target week.

### Trigger 2 — Performance stalled

```text
WeeklyChange[w] = ActualProductivity[w] - ActualProductivity[w - 1]
Trigger = WeeklyChange[w] < 3 percentage points
      AND WeeklyChange[w - 1] < 3 percentage points
      AND ActualProductivity[w] < RampTarget[w]
```

Example: Week 4 65%, Week 5 66%, Week 6 66%. Both improvements are under 3 points. The 3-point rule needs validation, especially because ramp expectations change by week.

### Trigger 8 — Within-week performance volatility

```text
DailyProductivity[day] = SUM(STDONLY for day) / SUM(ACTONLY for day) * 100
VolatilityRange = MAX(valid daily productivity within current workweek)
                - MIN(valid daily productivity within current workweek)
Trigger = Count(valid worked days) >= 3 AND VolatilityRange >= 20 percentage points
```

Example: Mon 85%, Tue 62%, Wed 91%, Thu 65%, Fri 88%; range = 29 percentage points, so the proposed volatility rule triggers. Evaluate during the week, as soon as at least three valid worked days are available. Compare sufficiently similar work assignments before interpreting the variation.

## Actionable application behavior

1. **Identify** colleagues who satisfy one or more triggers.
2. **Explain** the evidence: actual versus target, affected dates, trend, error counts, or loss categories.
3. **Prioritize** based on agreed business severity rules; do not assume all triggers have equal urgency.
4. **Consolidate** overlapping triggers into **one active colleague-level coaching recommendation**, rather than generating separate tasks for each issue.
5. **Recommend investigation**, not an unsupported root-cause conclusion. For example, compare work assignments before attributing low productivity to the colleague.
6. **Record supervisor action once** with date, selected follow-up, and notes.
7. **Monitor automatically** after coaching to assess subsequent performance and whether further follow-up is needed.
8. **Avoid repeated duplicate tasks** while an existing coaching recommendation remains active.

## Data dependencies and validation

| Data area | Intended use | Design consideration |
|---|---|---|
| Associate master and hire date | Identify new hires, supervisor assignment, ramp week | Validate hire date, transfers, and supervisor mapping. |
| Assignment-level actual and standard minutes | Weekly/daily productivity, ramp, trends, volatility | Confirm aggregation, valid worked days, comparable work types, and completeness. |
| TML / loss categories | Recurring TML trigger and investigation context | Agree on daily TML threshold and controllability rules. |
| Picker accuracy events | Repeated validated picking errors | Confirm error attribution and event availability. |
| Attendance / schedule data | Attendance concerns | **Not yet confirmed available**; require HR approval, restricted access, and exclusions for protected/approved leave. |
| DORA coaching actions | Coaching history and effectiveness | New application data must capture action date, supervisor, colleague, trigger evidence, and follow-up outcome. |

## Out of scope for Version 1

- **Low Utilization:** Explicitly removed from the coaching triggers for now.
- **Training Milestone Missed:** Removed because the necessary training milestone data is not available.

## Open decisions before implementation

- Confirm the complete 13-week ramp target schedule and treatment of partial weeks, leave, transfers, and insufficient work time.
- Validate proposed thresholds: stalled improvement (3 pp), declining performance (10 pp), volatility (20 pp), accuracy count (2), and recurring TML (3 days plus threshold).
- Decide whether a small below-target gap should trigger the two-week ramp rule or whether a tolerance should apply.
- Define minimum daily hours and comparability rules to avoid misleading productivity/volatility alerts.
- Confirm attendance data availability and policy approval before enabling that trigger.
- Define what constitutes meaningful improvement after coaching and how long an action remains open.
- Agree on supervisor action statuses, priority calculation, and trigger suppression/reopening rules.

## Proposed initial application screens

1. **New Hire Action Center:** Prioritized colleague-level coaching recommendations with concise evidence and next steps.
2. **Colleague Development Profile:** 13-week ramp, recent daily performance, triggers, accuracy, TML, and prior coaching history.
3. **Coaching & Follow-Up:** One supervisor action entry with automatically monitored outcomes.

**Architecture direction under exploration:** Power Apps Code Apps (React/TypeScript) for the interface, Microsoft Fabric SQL Database for application rules/actions/audit, and existing operational systems as the source of truth. End-to-end connectivity and operational feasibility still require validation.
