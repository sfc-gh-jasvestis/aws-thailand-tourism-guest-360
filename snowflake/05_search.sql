-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Guest Experience 360
-- ============================================================================
USE DATABASE GUEST_EXPERIENCE;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.GUEST_FEEDBACK_SEARCH
  ON REVIEW_TEXT
  ATTRIBUTES PROPERTY_ID, SOURCE_MARKET, RATING
  WAREHOUSE = GUEST_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.GUEST_REVIEWS
);
