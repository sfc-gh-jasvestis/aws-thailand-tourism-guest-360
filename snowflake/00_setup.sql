-- Generated from generator/demo_specs/aws-thailand-tourism-guest-360.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-thailand-tourism-guest-360
-- This is the schema that is actually deployed for THAILAND_TOURISM_GUEST_360.

-- THAILAND_TOURISM_GUEST_360  (Guest Experience 360)
-- generated from generator/demo_specs/aws-thailand-tourism-guest-360.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS THAILAND_TOURISM_GUEST_360;
CREATE SCHEMA IF NOT EXISTS THAILAND_TOURISM_GUEST_360.RAW;
CREATE SCHEMA IF NOT EXISTS THAILAND_TOURISM_GUEST_360.CURATED;
CREATE SCHEMA IF NOT EXISTS THAILAND_TOURISM_GUEST_360.APP;
USE DATABASE THAILAND_TOURISM_GUEST_360;

-- 5 real regions; entity names carry their region so the two always agree
