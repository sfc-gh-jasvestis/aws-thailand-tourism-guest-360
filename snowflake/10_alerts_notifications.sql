-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Guest Experience 360
-- ============================================================================
USE DATABASE GUEST_EXPERIENCE;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_thailand_tourism_guest_360_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: SENTIMENT_DROP_ALERT
CREATE OR REPLACE ALERT APP.SENTIMENT_DROP_ALERT
  WAREHOUSE = GUEST_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Guest sentiment declining at property'
IF (EXISTS (
  SELECT 1 FROM CURATED.GUEST_SENTIMENT_SCORES
  WHERE 1=1 -- Condition: AVG_SENTIMENT < 0.6 for any property over 7 days
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_tourism_guest_360_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Guest Experience 360: Guest sentiment declining at property',
    'Guest sentiment declining at property'
  );

ALTER ALERT APP.SENTIMENT_DROP_ALERT RESUME;

-- Alert: VIP_NEGATIVE_ALERT
CREATE OR REPLACE ALERT APP.VIP_NEGATIVE_ALERT
  WAREHOUSE = GUEST_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'VIP guest left negative review — immediate recovery needed'
IF (EXISTS (
  SELECT 1 FROM CURATED.GUEST_SENTIMENT_SCORES
  WHERE 1=1 -- Condition: LOYALTY_TIER = 'PLATINUM' AND REVIEW_SENTIMENT < 0.3
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_thailand_tourism_guest_360_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Guest Experience 360: VIP guest left negative review — immediate recovery needed',
    'VIP guest left negative review — immediate recovery needed'
  );

ALTER ALERT APP.VIP_NEGATIVE_ALERT RESUME;

