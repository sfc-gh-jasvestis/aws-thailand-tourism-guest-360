-- ============================================================================
-- Guest Experience 360
-- Unified guest profiles across 120 properties — Comprehend analyzes sentiment from reviews, Personalize drives recommendations via Cortex Complete, and SES delivers personalized communications through Notification Integration.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS GUEST_EXPERIENCE;
CREATE WAREHOUSE IF NOT EXISTS GUEST_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE GUEST_EXPERIENCE;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE GUEST_WH;
