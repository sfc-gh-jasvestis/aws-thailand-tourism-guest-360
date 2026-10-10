# Thailand Tourism Guest 360

**Thailand - Hotels and Tourism**
Use case: guest cohort retention, service recovery, lapse risk and CRM touch controls

> Guest 360 retention monitoring for 48 fictional loyalty guest cohorts of a fictional Thai hotel group, in Bangkok, Phuket, Chiang Mai, Pattaya and Krabi. Cohorts are aggregate guest groups; there are no individual guest records. The demo covers dynamic tables, a lapse-risk classifier evaluated on a time-based holdout, a service-issue forecast, cancellation rate anomaly detection, a Cortex Agent that cites guest recovery SOPs, a live engagement feed with an alert, and an SPCS app.

## Why Snowflake

- **Dynamic tables** turn cohort-day rows into stays, service issues, lapsed guests, unsubscribes and CRM touch compliance; `run_core.py` reconciles them against RAW on every build
- **Lapse-risk classification** gives each cohort a next-7-day probability that guests lapse, evaluated on a time-based holdout
- **Service-issue forecast** projects 14 days of group-wide service issues with prediction intervals, to plan guest relations cover
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, Search over SOPs) shows the SQL it ran and the SOPs it cited
- **Live engagement**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), feeding an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.COHORTS` (48 rows) |
| Fact table | `RAW.COHORT_DAILY` (4,320 cohort-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `ISSUE_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.CHURN_RISK_SCORES`, `ML.CHURN_RISK_HOLDOUT_METRICS`, `ML.ISSUE_FORECAST`, `ML.CANCEL_RATE_ANOMALIES` |

Currency: THB. Cities: Bangkok, Phuket, Chiang Mai, Pattaya, Krabi.
Segments: Leisure couples, Business travellers, Family holidaymakers, Long-stay visitors, Wellness travellers.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Issue-Free Stay Rate | 99.70% |
| Service Issues Raised | 875 |
| Lapsed Guests | 299 |
| Issue Churn Rate | 34.2% |
| Unsubscribes | 115 |
| Revenue (THB M) | 2,448 |
| Stays Completed | 290,855 |
| CRM Touch Compliance | 71.5% |
| Cohorts Monitored | 48 |
| Profile Completeness | 68.1% |
| Profile Fields Pending | 25 |

Values are synthetic. The data is HASH-seeded, so a rebuild reproduces them; dates are relative to the build day, and forecast and anomaly figures can shift slightly with the build day.

## Demo flow

1. Executive Cockpit: KPI cards, daily service issues against lapsed guests, issues and lapses by issue type, and the cohort table
2. Predictive: holdout metrics, risk bands, the 14-day service-issue forecast and cancellation rate anomalies
3. Controls: CRM touch compliance, profile completeness and pending profile fields, CRM touch compliance against lapsed guests, then the action memo
4. Live Engagement: run `CALL APP.SIMULATE_ENGAGEMENT(20)` (Snowflake only) or `python aws/publish_engagement.py --count 20` (AWS build), then `EXECUTE ALERT APP.LIVE_ENGAGEMENT_ALERT`, and show the alert log and email
5. Ask AI: the Cortex Agent answers metric questions through the semantic view, cites SOPs from Cortex Search and shows its SQL
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.70% of stays go through without a service issue. The 875 service issues are where guest relations spends its time, and 34.2% of them end with guests lapsing.
- **Points not credited** causes the most lapsed guests (72 of 197 issues), ahead of room not ready at check-in (62 of 177); the 20 regional booking platform outage issues (Phuket and Chiang Mai) were all resolved with the guests retained
- Cohorts in **Bangkok** have the most lapsed guests (103); Krabi has the fewest (37)
- On a time-based holdout the lapse-risk model reaches precision 0.67 and recall 0.49 at a 0.5 threshold, against a 0.30 base rate. Use it to decide which cohort gets a retention review first, not as a verdict on a cohort.
- Regional booking platform outages are left out of model training because the cohort did not cause them.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
