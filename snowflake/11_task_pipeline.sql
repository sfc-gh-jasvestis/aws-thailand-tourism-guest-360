-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Guest Experience 360
-- ============================================================================
USE DATABASE GUEST_EXPERIENCE;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_ANALYZE_REVIEWS
  WAREHOUSE = GUEST_WH
  SCHEDULE = 'USING CRON 0 */6 * * * UTC'
  COMMENT = 'Run AI_SENTIMENT on new reviews'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_GENERATE_PERSONALIZATION
  WAREHOUSE = GUEST_WH
  AFTER APP.TASK_ANALYZE_REVIEWS
  COMMENT = 'Generate personalized offers via Cortex Complete'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_SEND_COMMUNICATIONS
  WAREHOUSE = GUEST_WH
  AFTER APP.TASK_GENERATE_PERSONALIZATION
  COMMENT = 'Send targeted communications via Notification Integration'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_SEND_COMMUNICATIONS RESUME;
ALTER TASK APP.TASK_GENERATE_PERSONALIZATION RESUME;
ALTER TASK APP.TASK_ANALYZE_REVIEWS RESUME;
