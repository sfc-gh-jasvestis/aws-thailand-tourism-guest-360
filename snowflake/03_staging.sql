-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Guest Experience 360
-- Country: THAILAND | Currency: THB
-- ============================================================================
USE DATABASE GUEST_EXPERIENCE;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- GUEST_PROFILES: 180,000 rows — Unified guest profiles across all properties
-- STAY_HISTORY: 450,000 rows — Historical stay records with preferences and spend
-- GUEST_REVIEWS: 200,000 rows — Reviews from TripAdvisor, Google, Agoda, Booking.com
-- SERVICE_INTERACTIONS: 350,000 rows — Guest service requests, complaints, and resolutions
-- LOYALTY_PROGRAM: 85,000 rows — Loyalty tier data, points, and redemptions
-- PERSONALIZATION_ACTIONS: 25,000 rows — AI-generated personalized recommendations and offers
-- COMPETITOR_REVIEWS: 50,000 rows — Competitive set review data for benchmarking
-- THAI_TOURISM_TRENDS: 12 rows — Thailand tourism demographic and spending trends
