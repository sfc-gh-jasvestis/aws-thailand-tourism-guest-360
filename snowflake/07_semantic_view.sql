-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Guest Experience 360
-- ============================================================================
USE DATABASE GUEST_EXPERIENCE;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.GUEST_ANALYTICS
  COMMENT = 'Guest satisfaction, lifetime value, and personalization analytics'
AS
  TABLES (
    CURATED.GUEST_SENTIMENT_SCORES AS guest_sentiment_scores,CURATED.GUEST_LIFETIME_VALUE AS guest_lifetime_value,CURATED.SERVICE_RECOVERY_QUEUE AS service_recovery_queue,CURATED.PROPERTY_NPS_TRENDS AS property_nps_trends
  );
