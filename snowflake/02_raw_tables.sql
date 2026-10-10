-- Synthetic guest-cohort-day observations for a fictional Thai hotel group.
-- A cohort is an aggregate group of loyalty guests in one Thai city and one
-- travel segment; no individual guest records exist. Nothing is seeded as a
-- prediction. Randomness is HASH-seeded, so every rebuild is reproducible:
-- per-cohort lapse propensity, engagement decay between CRM touches, missed
-- touches, segment-weighted service issue types, issues resolved with the
-- guests retained, and two city-wide booking platform outages.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.COHORTS AS
WITH cohorts AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS COHORT_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 48))
), draws AS (
  SELECT COHORT_INDEX,
         MOD(ABS(HASH(COHORT_INDEX, 'thg360-tenure')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(COHORT_INDEX, 'thg360-lapserate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(COHORT_INDEX, 'thg360-cadence')), 1000000) / 1e6 AS U_TOUCH,
         MOD(ABS(HASH(COHORT_INDEX, 'thg360-crmdisc')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(COHORT_INDEX, 'thg360-riskband')), 1000000) / 1e6 AS U_TIER
  FROM cohorts
)
SELECT 'GCH-' || LPAD(COHORT_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic guest cohort ' || LPAD(COHORT_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every city and segment is present.
       CASE MOD(COHORT_INDEX, 5) WHEN 0 THEN 'Bangkok' WHEN 1 THEN 'Phuket'
            WHEN 2 THEN 'Chiang Mai' WHEN 3 THEN 'Pattaya' ELSE 'Krabi' END AS REGION,
       CASE MOD(COHORT_INDEX, 8) WHEN 0 THEN 'Leisure couples' WHEN 1 THEN 'Leisure couples'
            WHEN 2 THEN 'Leisure couples' WHEN 3 THEN 'Business travellers' WHEN 4 THEN 'Business travellers'
            WHEN 5 THEN 'Family holidaymakers' WHEN 6 THEN 'Long-stay visitors' ELSE 'Wellness travellers' END AS SEGMENT,
       COHORT_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.2 + U_AGE * 9.0, 1) AS TENURE_YEARS,
       -- Base daily probability of a lapse event 0.4%-3.0%; ~16% of cohorts are
       -- chronically weak (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.84, 3, 1) AS BASE_CHURN_RATE,
       7 * (1 + FLOOR(U_TOUCH * 3)) AS TOUCH_INTERVAL_DAYS,
       0.45 + U_DISCIPLINE * 0.5 AS TOUCH_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.COHORT_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two city-wide booking platform outages; every cohort in the city raises a
  -- service issue that is resolved once the platform is back.
  SELECT * FROM VALUES (31, 'Phuket'), (64, 'Chiang Mai') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT s.ID AS ENTITY_ID, s.COHORT_INDEX, s.SEGMENT, s.REGION, s.TENURE_YEARS,
         s.BASE_CHURN_RATE, s.TOUCH_INTERVAL_DAYS, s.TOUCH_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + s.COHORT_INDEX * 5, s.TOUCH_INTERVAL_DAYS) AS DAYS_SINCE_TOUCH,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thg360-lapse')), 1000000) / 1e6 AS U_CHURN,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thg360-complain')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thg360-recover')), 1000000) / 1e6 AS U_RESOLVE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thg360-issuekind')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thg360-touchmade')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thg360-roomnights')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thg360-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'thg360-unsub')), 1000000) / 1e6 AS U_UNSUB,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.COHORTS s CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = s.REGION
), touches AS (
  SELECT *,
         IFF(DAYS_SINCE_TOUCH = 0, 1, 0) AS TOUCH_DUE,
         IFF(DAYS_SINCE_TOUCH = 0 AND U_DONE < TOUCH_COMPLETION_PROB, 1, 0) AS TOUCH_DONE,
         -- Engagement decay rises between CRM touches; weak touch discipline
         -- carries it over.
         DAYS_SINCE_TOUCH / TOUCH_INTERVAL_DAYS + (1 - TOUCH_COMPLETION_PROB) AS DRIFT
  FROM base
), churns AS (
  SELECT *,
         CASE WHEN U_CHURN < LEAST(0.5, BASE_CHURN_RATE * (0.3 + 1.8 * DRIFT) * (1 + 1.1 / (1 + TENURE_YEARS))) / 4 THEN 2
              WHEN U_CHURN < LEAST(0.5, BASE_CHURN_RATE * (0.3 + 1.8 * DRIFT) * (1 + 1.1 / (1 + TENURE_YEARS))) THEN 1
              ELSE 0 END AS CHURN_RISK_COUNT
  FROM touches
), issues AS (
  SELECT *,
         -- About 80% of at-risk guests raise a service issue and then lapse;
         -- the rest drift away quietly without raising one.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.80, CHURN_RISK_COUNT, 0)) AS CHURNED_COUNT,
         -- Issues resolved with the guests retained: higher for long-stay guests.
         IFF(CITY_EVENT, 1, IFF(U_RESOLVE < CASE SEGMENT WHEN 'Long-stay visitors' THEN 0.20
                                                          WHEN 'Business travellers' THEN 0.16
                                                          WHEN 'Wellness travellers' THEN 0.13
                                                          WHEN 'Leisure couples' THEN 0.10 ELSE 0.08 END, 1, 0)) AS RESOLVED_COUNT
  FROM churns
), measured AS (
  SELECT *,
         CHURNED_COUNT + RESOLVED_COUNT AS ISSUE_COUNT,
         ROUND(CASE SEGMENT WHEN 'Leisure couples' THEN 95 WHEN 'Business travellers' THEN 70
                            WHEN 'Family holidaymakers' THEN 45 WHEN 'Long-stay visitors' THEN 18 ELSE 30 END
               * (0.7 + 0.6 * U_VOLUME) * (1 + 0.5 * CHURN_RISK_COUNT)) AS STAY_COUNT,
         CASE SEGMENT WHEN 'Leisure couples' THEN 7800 WHEN 'Business travellers' THEN 5200
                      WHEN 'Family holidaymakers' THEN 11500 WHEN 'Long-stay visitors' THEN 26000 ELSE 14500 END
           * (0.8 + 0.4 * U_NOISE) AS AVG_STAY_THB
  FROM issues
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       STAY_COUNT,
       ROUND(STAY_COUNT * AVG_STAY_THB, 0) AS REVENUE_THB,
       ISSUE_COUNT, CHURNED_COUNT,
       IFF(CHURNED_COUNT > 0 AND U_UNSUB < 0.5, 1, 0) AS UNSUBSCRIBED,
       CASE WHEN ISSUE_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Regional booking platform outage'
            WHEN SEGMENT = 'Leisure couples' THEN IFF(U_TYPE < 0.45, 'Room not ready at check-in', IFF(U_TYPE < 0.8, 'Points not credited', 'Airport transfer delay'))
            WHEN SEGMENT = 'Business travellers' THEN IFF(U_TYPE < 0.4, 'Wi-Fi outage', IFF(U_TYPE < 0.75, 'Points not credited', 'Late checkout refused'))
            WHEN SEGMENT = 'Family holidaymakers' THEN IFF(U_TYPE < 0.55, 'Room not ready at check-in', 'Kids club fully booked')
            WHEN SEGMENT = 'Long-stay visitors' THEN IFF(U_TYPE < 0.45, 'Housekeeping missed', IFF(U_TYPE < 0.8, 'Billing dispute', 'Noise complaint'))
            ELSE IFF(U_TYPE < 0.5, 'Spa booking clash', IFF(U_TYPE < 0.75, 'Airport transfer delay', 'Room not ready at check-in')) END AS ISSUE_TYPE,
       TOUCH_DUE, TOUCH_DONE,
       ROUND(2.5 + 3.0 * DRIFT + 3.4 * CHURN_RISK_COUNT + U_NOISE * 1.4, 2) AS CANCEL_RATE_PCT,
       ROUND(3 + 7 * DRIFT + 9 * CHURN_RISK_COUNT + U_NOISE * 3, 1) AS AVG_RESPONSE_HRS,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Loyalty profile field completeness per cohort (aggregate snapshot).
CREATE TABLE RAW.PROFILE_FIELDS AS
SELECT ID AS ENTITY_ID,
       CASE SEGMENT WHEN 'Leisure couples' THEN 'Room preference'
                    WHEN 'Business travellers' THEN 'Company billing profile'
                    WHEN 'Family holidaymakers' THEN 'Family room profile'
                    WHEN 'Long-stay visitors' THEN 'Stay length preference'
                    ELSE 'Treatment preference' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'thg360-profreq')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'thg360-profhave')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'thg360-profhave')), 5) < 1 + MOD(ABS(HASH(ID, 'thg360-profreq')), 4),
           MOD(ABS(HASH(ID, 'thg360-profwait')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.COHORTS;
