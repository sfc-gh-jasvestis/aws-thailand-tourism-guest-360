-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-engagement alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_ENGAGEMENT.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic service-issue knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.ISSUE_DOCS AS
WITH types AS (
  SELECT DISTINCT r.ISSUE_TYPE, a.SEGMENT
  FROM RAW.COHORT_DAILY r JOIN RAW.COHORTS a ON a.ID = r.ENTITY_ID
  WHERE r.CHURNED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEGMENT, ISSUE_TYPE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  SEGMENT,
  ISSUE_TYPE,
  SEGMENT || ' - ' || ISSUE_TYPE || ' service issue handling' AS TITLE,
  'Synthetic demo SOP. Travel segment: ' || SEGMENT || '. Service issue type: ' || ISSUE_TYPE || '. '
  || 'Step 1: open a guest recovery case against the cohort, acknowledge the affected guests through their preferred channel within 2 hours, and pause promotional sends to that cohort until the guest relations team triages the case. '
  || 'Step 2: ' || CASE
       WHEN ISSUE_TYPE = 'Points not credited' THEN 'reconcile the loyalty ledger against the folio records, post the missing points in one batch, and add goodwill points for guests who raised the issue twice.'
       WHEN ISSUE_TYPE = 'Room not ready at check-in' THEN 'offer lounge access and a drink voucher while housekeeping completes the room, confirm a ready time, and log the delay against the front office handover.'
       WHEN ISSUE_TYPE = 'Airport transfer delay' THEN 'confirm the revised pick-up time with the transfer partner, refund the transfer fee when the wait exceeds 30 minutes, and flag the partner in the weekly vendor review.'
       WHEN ISSUE_TYPE = 'Wi-Fi outage' THEN 'move the guest to a room on a working access point or issue a mobile data voucher, and raise a ticket with the IT team with the floor and time.'
       WHEN ISSUE_TYPE = 'Late checkout refused' THEN 'check the loyalty tier entitlement and occupancy, grant the late checkout when the tier allows it, and brief the front office on the entitlement.'
       WHEN ISSUE_TYPE = 'Kids club fully booked' THEN 'offer the next available kids club session or an alternative family activity, and review kids club capacity for peak school holiday weeks.'
       WHEN ISSUE_TYPE = 'Housekeeping missed' THEN 'schedule a priority room clean within the hour, apologise in writing, and review the housekeeping roster for the floor.'
       WHEN ISSUE_TYPE = 'Billing dispute' THEN 'compare the folio with the booking terms, correct and reissue the invoice, and refund any overcharge to the original payment method.'
       WHEN ISSUE_TYPE = 'Noise complaint' THEN 'offer a room move to a quieter floor, contact the source of the noise, and log the room numbers for the duty manager.'
       WHEN ISSUE_TYPE = 'Spa booking clash' THEN 'rebook the treatment at the closest free slot with the preferred therapist, add a complimentary upgrade, and correct the spa calendar sync.'
       ELSE 'review the issue against the cohort history and escalate to the duty manager if the cause is unclear.'
     END
  || ' Step 3: keep the case open and schedule a cohort retention review when, after triage, the cohort cancellation rate is above 8% or the average service response time is above 12 hours. '
  || 'Step 4: close the case with the outcome; for guests who lapsed or unsubscribed, add the cohort to the next win-back campaign and to the weekly guest health report.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.ISSUE_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES SEGMENT, ISSUE_TYPE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, SEGMENT, ISSUE_TYPE, CONTENT FROM SEARCH.ISSUE_DOCS);

-- ---------- Cancellation rate anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.CANCEL_RATE_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, CANCEL_RATE_PCT::FLOAT AS CANCEL_RATE
FROM RAW.COHORT_DAILY;
CREATE OR REPLACE VIEW ML.CANCEL_RATE_TRAIN AS
SELECT * FROM ML.CANCEL_RATE_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.CANCEL_RATE_SERIES);
CREATE OR REPLACE VIEW ML.CANCEL_RATE_DETECT AS
SELECT * FROM ML.CANCEL_RATE_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.CANCEL_RATE_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.CANCEL_RATE_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.CANCEL_RATE_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'CANCEL_RATE',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.CANCEL_RATE_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS CANCEL_RATE, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.CANCEL_RATE_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.CANCEL_RATE_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'CANCEL_RATE'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.GUEST360_ANALYTICS
  TABLES (
    cohorts AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'guest cohorts', 'segments of guests')
      COMMENT = 'One row per loyalty cohort (Thai city and travel segment), 90-day aggregate totals',
    risk AS ML.CHURN_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day churn probability per cohort',
    issues AS CURATED.ISSUE_SUMMARY PRIMARY KEY (ISSUE_TYPE)
      COMMENT = 'Service issues, lapsed guests and unsubscribes by issue type, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Group-wide totals per day'
  )
  RELATIONSHIPS (risk_cohort AS risk (ENTITY_ID) REFERENCES cohorts)
  FACTS (
    cohorts.issues_f AS ISSUE_COUNT,
    cohorts.churned_f AS CHURNED_COUNT,
    cohorts.unsub_f AS UNSUBSCRIBE_COUNT,
    cohorts.stays_f AS STAY_COUNT,
    cohorts.revenue_f AS REVENUE_THB,
    cohorts.touch_due_f AS TOUCH_DUE,
    cohorts.touch_done_f AS TOUCH_DONE,
    risk.churn_prob_f AS CHURN_PROB_7D,
    issues.type_issues_f AS ISSUE_COUNT,
    issues.type_churned_f AS CHURNED_COUNT,
    issues.type_unsub_f AS UNSUBSCRIBE_COUNT,
    issues.type_revenue_f AS EXPOSED_REVENUE_THB,
    daily.day_issues_f AS ISSUE_COUNT,
    daily.day_churned_f AS CHURNED_COUNT,
    daily.day_revenue_f AS REVENUE_THB
  )
  DIMENSIONS (
    cohorts.cohort_id AS ENTITY_ID WITH SYNONYMS = ('cohort', 'guest cohort', 'entity', 'guest group'),
    cohorts.cohort_name AS ENTITY_NAME,
    cohorts.city AS REGION WITH SYNONYMS = ('city', 'region', 'location')
      COMMENT = 'Thai city where the cohort stays',
    cohorts.segment AS SEGMENT WITH SYNONYMS = ('travel segment', 'guest segment'),
    cohorts.risk_tier AS RISK_TIER COMMENT = 'Cohort retention risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    issues.issue_type AS ISSUE_TYPE WITH SYNONYMS = ('issue', 'complaint type', 'issue reason'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    cohorts.cohort_count AS COUNT(cohorts.cohort_id) WITH SYNONYMS = ('number of cohorts', 'number of entities', 'how many cohorts'),
    cohorts.clean_stay_rate_pct AS 100 * (SUM(cohorts.stays_f) - SUM(cohorts.issues_f)) / NULLIF(SUM(cohorts.stays_f), 0)
      WITH SYNONYMS = ('issue-free stay rate', 'clean stay rate')
      COMMENT = 'Stays without a service issue / stays completed',
    cohorts.issue_churn_pct AS 100 * SUM(cohorts.churned_f) / NULLIF(SUM(cohorts.issues_f), 0)
      COMMENT = 'Lapsed guests / service issues raised',
    cohorts.issues_raised AS SUM(cohorts.issues_f) WITH SYNONYMS = ('service issues', 'complaints'),
    cohorts.lapsed_guests AS SUM(cohorts.churned_f) WITH SYNONYMS = ('churn', 'lapsed guests', 'churned'),
    cohorts.unsubscribes AS SUM(cohorts.unsub_f) WITH SYNONYMS = ('unsubscribed', 'opt-outs'),
    cohorts.stays_completed AS SUM(cohorts.stays_f) WITH SYNONYMS = ('stays', 'room stays'),
    cohorts.total_revenue_thb AS SUM(cohorts.revenue_f) WITH SYNONYMS = ('revenue', 'room revenue', 'revenue in THB'),
    cohorts.touch_compliance_pct AS 100 * SUM(cohorts.touch_done_f) / NULLIF(SUM(cohorts.touch_due_f), 0)
      COMMENT = 'CRM touches completed / CRM touches due',
    risk.avg_churn_prob AS AVG(risk.churn_prob_f),
    issues.type_issues AS SUM(issues.type_issues_f),
    issues.type_churned AS SUM(issues.type_churned_f),
    issues.type_unsub AS SUM(issues.type_unsub_f),
    issues.type_churn_share_pct AS 100 * SUM(issues.type_churned_f) / NULLIF(SUM(issues.type_issues_f), 0),
    daily.daily_issues AS SUM(daily.day_issues_f),
    daily.daily_churned AS SUM(daily.day_churned_f),
    daily.daily_revenue_thb AS SUM(daily.day_revenue_f)
  )
  COMMENT = 'Synthetic Thailand tourism guest 360 analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.GUEST360_AGENT
  COMMENT = 'Guest 360 assistant over synthetic loyalty cohorts of a fictional Thai hotel group'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give cohort IDs and numbers with units (THB, %)."
  orchestration: "Use guest360_analyst for stays, revenue, service issues, lapsed guests, unsubscribes, issue-free stay rate, CRM touch compliance, cohorts, cities, segments, issue types and churn risk. Use sop_search for service-issue handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: guest360_analyst
      description: "Stays, revenue in THB, service issues, lapsed guests, unsubscribes, issue-free stay rate, CRM touch compliance, issue types and churn risk scores by cohort, city and segment"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic service-issue handling SOPs by travel segment and issue type"
tool_resources:
  guest360_analyst:
    semantic_view: __DEMO_DB__.APP.GUEST360_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.ISSUE_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-engagement alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), COHORT_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, AMOUNT_THB FLOAT, RESPONSE_MINUTES FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION TH_TOURISM_GUEST_360_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (COHORT_ID, EVENT_TS, AMOUNT_THB, RESPONSE_MINUTES, SOP_HINT)
    SELECT p.COHORT_ID, p.EVENT_TS, p.AMOUNT_THB, p.RESPONSE_MINUTES,
           'Check ' || r.SEGMENT || ' service-issue SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_ENGAGEMENT p
    JOIN RAW.COHORTS r ON r.ID = p.COHORT_ID
    LEFT JOIN ML.CHURN_RISK_SCORES s ON s.ENTITY_ID = p.COHORT_ID
    WHERE p.STATUS = 'ISSUE'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.COHORT_ID = p.COHORT_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('TH_TOURISM_GUEST_360_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Service issue alert',
      'New live service issues logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ENGAGEMENT_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_ENGAGEMENT p
    WHERE p.STATUS = 'ISSUE'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.COHORT_ID = p.COHORT_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.ISSUE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.CHURN_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.CHURN_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.CHURN_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'SEGMENT', SEGMENT, 'RISK_TIER', RISK_TIER, 'TENURE_YEARS', TENURE_YEARS,
             'CANCEL_RATE_PCT', CANCEL_RATE_PCT, 'AVG_RESPONSE_HRS', AVG_RESPONSE_HRS,
             'CANCEL_RATE_7D', CANCEL_RATE_7D, 'CHURNED_30D', CHURNED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:CHURN::FLOAT, 4) AS CHURN_PROB_7D,
         CASE WHEN PRED:probability:CHURN::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:CHURN::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
