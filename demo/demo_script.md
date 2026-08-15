# Demo Script: Guest Experience 360
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake unifies guest data across 120 properties, analyzes sentiment from 200K reviews, generates personalized recommendations, and delivers targeted communications — all native SQL, replacing fragmented guest CRM"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Natthawut Thongprasert** | VP Guest Experience | React App (SPCS) | Guest satisfaction scores, loyalty metrics, lifetime value, service recovery |
| **Ploy Suwannapha** | Guest Relations Manager | Amazon QuickSight | Individual guest preferences, service recovery alerts, upsell opportunities, loyalty tier management |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 8 tables | GUEST_PROFILES (180000), STAY_HISTORY (450000), GUEST_REVIEWS (200000), SERVICE_INTERACTIONS (350000), LOYALTY_PROGRAM (85000), PERSONALIZATION_ACTIONS (25000), COMPETITOR_REVIEWS (50000), THAI_TOURISM_TRENDS (12) |
| **CURATED** | 4 Dynamic Tables | GUEST_SENTIMENT_SCORES, GUEST_LIFETIME_VALUE, SERVICE_RECOVERY_QUEUE, PROPERTY_NPS_TRENDS |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | AI_SENTIMENT, COMPLETE, AI_EXTRACT | Classification + extraction |
| **Search** | Cortex Search | 200000 documents indexed |
| **Agent** | GUEST_EXPERIENCE_AGENT | Semantic View + Search tools |


---

## The Story

Thailand's premier hotel group manages 120 properties hosting 180,000 guests annually. Guest reviews across 4 languages reveal declining satisfaction — but fragmented data across OTA platforms means 342 unhappy guests are waiting for recovery while personalization opportunities worth ฿95M go untapped.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "Portfolio guest sentiment at 0.72 — down from 0.78 last quarter."

**Action**: Point at sentiment trend chart

### [0:45–1:30] SENTIMENT INTELLIGENCE

**Show**: Sentiment Intelligence tab

> "AI_SENTIMENT analyzes 200K reviews in Thai, English, Chinese, and Korean."

**Action**: Show sentiment heatmap by property and topic

### [1:30–2:15] GUEST PERSONALIZATION

**Show**: Guest Personalization tab

> "Cortex Complete generates personalized recommendations for 25,000 upcoming stays."

**Action**: Show personalization recommendation cards

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Natthawut asks: 'Which properties have the most negative Chinese guest reviews?'"

**Action**: Type: 'Properties with most negative Chinese reviews'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Seven Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **AI_SENTIMENT on multilingual reviews** — Only demo analyzing guest sentiment in Thai, English, Chinese, and Korean simultaneously
2. **Cortex Complete for personalized guest offers** — AI-generated personalized recommendations based on full stay history and preferences
3. **Service recovery automation** — End-to-end: negative review → AI drafts apology → sends via Notification Integration
4. **Thai hospitality context** — 120 properties across 4 Thai destinations with realistic multi-source-market guest data
5. **Guest lifetime value via Dynamic Tables** — Real-time CLV calculation driving personalization investment decisions
6. **Competitive sentiment benchmarking** — 50K competitor reviews analyzed for relative positioning


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM GUEST_EXPERIENCE.RAW.GUEST_REVIEWS` → 200000
- [ ] `SELECT COUNT(*) FROM GUEST_EXPERIENCE.RAW.GUEST_PROFILES` → 180000
- [ ] `SELECT COUNT(*) FROM GUEST_EXPERIENCE.CURATED.SERVICE_RECOVERY_QUEUE` → ~342

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM GUEST_EXPERIENCE.ML.SATISFACTION_FORECAST_RESULTS` → >0
- [ ] `SELECT SUM(CASE WHEN IS_ANOMALY THEN 1 ELSE 0 END) FROM GUEST_EXPERIENCE.ML.SENTIMENT_ANOMALY_RESULTS` → >=5

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM GUEST_EXPERIENCE.AI.SENTIMENT_SCORES WHERE SENTIMENT < 0.3` → >5000

