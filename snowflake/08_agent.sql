-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Guest Experience 360
-- ============================================================================
USE DATABASE GUEST_EXPERIENCE;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.GUEST_EXPERIENCE_AGENT
  COMMENT = 'Guest Experience 360 AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'GUEST_EXPERIENCE.APP.GUEST_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'GUEST_EXPERIENCE.SEARCH.GUEST_FEEDBACK_SEARCH', TOOL_DESCRIPTION => 'Search documents for Tourism & Hospitality information')
  )
  SYSTEM_PROMPT = 'You are the Guest Experience Agent for 120 Thai resort properties, helping optimize guest satisfaction and personalization.';
