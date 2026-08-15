-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Guest Experience 360
-- ============================================================================
USE DATABASE GUEST_EXPERIENCE;
USE SCHEMA CURATED;

-- GUEST_SENTIMENT_SCORES: Real-time sentiment scoring from all review sources
-- Source: GUEST_REVIEWS
CREATE OR REPLACE DYNAMIC TABLE CURATED.GUEST_SENTIMENT_SCORES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = GUEST_WH
AS
SELECT * FROM RAW.GUEST_REVIEWS;
-- TODO: Replace with actual join/aggregation logic per demo

-- GUEST_LIFETIME_VALUE: CLV calculation by guest segment and source market
-- Source: GUEST_PROFILES, STAY_HISTORY
CREATE OR REPLACE DYNAMIC TABLE CURATED.GUEST_LIFETIME_VALUE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = GUEST_WH
AS
SELECT * FROM RAW.GUEST_PROFILES;
-- TODO: Replace with actual join/aggregation logic per demo

-- SERVICE_RECOVERY_QUEUE: Guests requiring follow-up based on negative sentiment
-- Source: GUEST_REVIEWS, SERVICE_INTERACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.SERVICE_RECOVERY_QUEUE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = GUEST_WH
AS
SELECT * FROM RAW.GUEST_REVIEWS;
-- TODO: Replace with actual join/aggregation logic per demo

-- PROPERTY_NPS_TRENDS: Property-level NPS trending for executive view
-- Source: GUEST_REVIEWS, SERVICE_INTERACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.PROPERTY_NPS_TRENDS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = GUEST_WH
AS
SELECT * FROM RAW.GUEST_REVIEWS;
-- TODO: Replace with actual join/aggregation logic per demo

