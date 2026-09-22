Weekly Colleague Performance Clustering Model

1. Purpose

Build a machine learning model that runs every Monday and analyzes each colleague’s performance from the previous week.

The objective is to identify different performance patterns across colleagues rather than looking only at average LMS performance.

The model will group colleagues with similar weekly performance behaviors into clusters that can support coaching, operational analysis, and process improvement.

⸻

2. Core Question

How did each colleague perform last week, and what type of performance pattern did they demonstrate?

The model should consider:

* Overall performance
* Consistency
* Utilization
* Operational losses
* Work-type mix
* Week-over-week movement
* Daily performance behavior

⸻

3. Source Data Grain

Because colleagues can work multiple work types within the same day, the source data should first be summarized at:

Colleague × Date × Work Type

Example:

Colleague	Date	Work Type	ACTMIN	STDMIN	Performance
A123	Monday	Selection	240	252	105%
A123	Monday	Stocking	120	108	90%
A123	Tuesday	Selection	360	374	104%

This preserves the operational context of each work type.

⸻

4. Weekly Model Grain

The clustering model itself should operate at:

1 row = 1 Colleague × 1 Week

The daily and work-type-level data is aggregated into weekly features before being passed into the model.

Example:

Colleague	Week	Weekly Perf	Std Dev Perf	Utilization	Gap %	BRLU %	Work Types
A123	Sep 14–20	101.5%	4.2	93%	2.8%	3.1%	2

⸻

5. Weekly Performance Calculation

Performance should not be calculated by simply averaging daily or work-type percentages.

Use a weighted calculation:

[
Weekly\ Performance =
\frac{\sum STDMIN}{\sum ACTMIN}
]

This ensures that a work type performed for 30 minutes does not influence the weekly result as much as a work type performed for 300 minutes.

⸻

6. Initial Model Features

Performance

Weekly Performance %

Overall weighted LMS performance for the week.

Daily Performance Standard Deviation

Measures how consistent the colleague was across the week.

Example:

Colleague A:

99%, 101%, 100%, 102%, 98%

Weekly average = 100%
Standard deviation ≈ 1.4 points

Colleague B:

80%, 120%, 90%, 115%, 95%

Weekly average = 100%
Standard deviation ≈ 15.2 points

Both colleagues average 100%, but their weekly behavior is very different.

⸻

Utilization and Loss

Utilization %

How much available work time was productively utilized.

Gap %

[
Gap% = \frac{GapMinutes}{ACTMIN}
]

BRLU %

[
BRLU% = \frac{BRLUMinutes}{ACTMIN}
]

Begin Day Loss

Total Begin Day miss minutes during the week.

⸻

Consistency

% of Days Below 100%

Example:

If a colleague worked 5 days and was below 100% performance on 2 days:

[
2/5 = 40%
]

This gives another view of consistency beyond standard deviation.

⸻

Trend

Week-over-Week Performance Change

Example:

Previous week = 96%
Current week = 101%

WoW change = +5 percentage points

This helps distinguish improving colleagues from declining colleagues.

⸻

7. Work-Type Mix

Because colleagues may work several functions within the same day or week, work-type mix should be included in the weekly profile.

Example:

Work Type	Minutes	% of Weekly Time
Selection	1,200	67%
Stocking	450	25%
Receiving	150	8%

Potential features:

* % Selection minutes
* % Stocking minutes
* % Receiving minutes
* % Shipping minutes
* Number of work types worked
* Primary work type
* % of time spent in primary work type

This prevents the model from treating assignment differences as colleague performance differences.

⸻

8. Suggested First-Version Feature Set

Start simple.

The first model could use:

1. Weekly Performance %
2. Daily Performance Standard Deviation
3. Utilization %
4. Gap %
5. BRLU %
6. Begin Day Loss
7. % Days Below 100%
8. Week-over-Week Performance Change
9. Number of Work Types
10. Primary Work-Type %
11. Work-Type Mix %
12. Total ACTMIN / Hours Worked

More features can be added later if they improve the clusters.

⸻

9. Machine Learning Approach

Model Type

Unsupervised Machine Learning

Initial Algorithm

K-Means Clustering

The model is not told which colleague is good or bad.

Instead, it analyzes similarities across the weekly features and identifies naturally occurring groups.

⸻

10. Example Clusters

The actual clusters should be determined by the data first.

After the model identifies them, operations can apply meaningful names.

Example:

Cluster 1 — Consistently Strong

High performance
High utilization
Low standard deviation
Low operational loss

Cluster 2 — Strong Performance With Barriers

Good performance
Higher Gap or BRLU
Good productivity despite process losses

Cluster 3 — Productivity Opportunity

Lower performance
Good utilization
Low process loss

This may indicate a method, skill, or work-type-specific opportunity.

Cluster 4 — High Variability

Acceptable average performance
High standard deviation
Large daily swings

Cluster 5 — Process Loss Opportunity

Lower utilization
Higher Gap / BRLU / BD loss
Performance may not be the primary issue

Cluster 6 — Improving

Positive week-over-week trend
Performance moving toward or above target

The number of clusters should not be predetermined solely by business preference. We should test different cluster counts and determine which provides meaningful separation.

⸻

11. Weekly Processing Flow

Every Monday:

Step 1

Pull the previous week’s LMS data.

Step 2

Aggregate assignment-level data into:

Colleague × Date × Work Type

Step 3

Create daily colleague-level metrics where required.

Step 4

Calculate weekly colleague features.

Step 5

Normalize the ML features so metrics with large numeric ranges do not dominate clustering.

Step 6

Run the clustering model.

Step 7

Assign each colleague to a cluster.

Step 8

Publish the cluster results into the reporting layer / Power BI.

⸻

12. Architecture

LMS / Snowflake Data

↓

Colleague × Day × Work Type dataset

↓

Weekly Feature Engineering

↓

Colleague × Week feature table

↓

Feature Scaling

↓

K-Means Clustering

↓

Cluster Assignment

↓

Power BI / Coaching Dashboard

⸻

13. Example Output

A supervisor could see:

Colleague: A123

Weekly Performance: 104%
Utilization: 94%
Performance Std Dev: 3.1
Gap: 2.4%
BRLU: 2.8%
WoW Change: +4 pts
Work Types: Selection 72%, Stocking 28%

Cluster: Consistently Strong

Another colleague could show:

Colleague: B456

Weekly Performance: 101%
Utilization: 90%
Performance Std Dev: 14.8
Gap: 4.5%
WoW Change: -2 pts

Cluster: High Variability

The weekly averages may be similar, but the operational behaviors are very different.

⸻

14. Historical Tracking

The Monday model should save the weekly cluster assignment rather than overwrite it.

Example:

Colleague	Week	Cluster
A123	Week 35	High Variability
A123	Week 36	Improving
A123	Week 37	Consistently Strong

This creates another valuable metric:

Cluster Movement

The business can understand whether a colleague is:

* remaining consistent
* improving
* becoming more variable
* experiencing new process barriers

⸻

15. What the Model Should Not Do

The clusters should not automatically determine disciplinary or employment actions.

The model should act as a coaching and operational diagnostic signal.

Its purpose is to help supervisors understand:

What happened?

Was it consistent?

Is it primarily performance or process loss?

Is the colleague improving or declining?

Does the pattern change depending on work type?

The supervisor then adds the operational context the model cannot see.

⸻

16. Initial MVP

For the first prototype:

Population: Selection colleagues at one DC

History: 8–12 weeks

Weekly features:

* Performance %
* Std Dev Performance
* Utilization %
* Gap %
* BRLU %
* Begin Day Loss
* % Days Below 100%
* WoW Performance Change
* Work-Type Mix
* Hours Worked

Model: K-Means

Output: 4–6 naturally occurring colleague performance patterns

Once the clusters make operational sense, the model can be tested across additional DCs and work types.