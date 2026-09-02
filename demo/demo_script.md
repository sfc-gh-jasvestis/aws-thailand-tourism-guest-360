# Guest Experience 360

**Thailand - Tourism & Hospitality**
Use case: Guest Experience & Personalization

> Unified guest profiles across 120 properties — Comprehend analyzes sentiment from reviews, Personalize drives recommendations via Cortex Complete, and SES delivers personalized communications through Notification Integration.

## Why Snowflake

Snowflake unifies guest data across 120 properties, analyzes sentiment from 200K reviews, generates personalized recommendations, and delivers targeted communications — all native SQL, replacing fragmented guest CRM

- **AI_SENTIMENT on multilingual reviews** - Only demo analyzing guest sentiment in Thai, English, Chinese, and Korean simultaneously
- **Cortex Complete for personalized guest offers** - AI-generated personalized recommendations based on full stay history and preferences
- **Service recovery automation** - End-to-end: negative review → AI drafts apology → sends via Notification Integration
- **Thai hospitality context** - 120 properties across 4 Thai destinations with realistic multi-source-market guest data
- **Guest lifetime value via Dynamic Tables** - Real-time CLV calculation driving personalization investment decisions
- **Competitive sentiment benchmarking** - 50K competitor reviews analyzed for relative positioning

## What is deployed

| | |
|---|---|
| Database | `THAILAND_TOURISM_GUEST_360` |
| Service | `THAILAND_TOURISM_GUEST_360_APP` |
| Compute pool | `SEA_DEMOS_THAILAND_POOL` |
| Dimension table | `RAW.THAI_TOURISM_TRENDS` (20 rows) |
| Fact table | `RAW.STAY_HISTORY` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | THB (฿) |

Regions in play: Bangkok, Chonburi, Rayong, Chiang Mai, Songkhla
Segments: Luxury Resort, Boutique, City Business, Serviced Apartment

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh THAILAND_TOURISM_GUEST_360
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Guest Profiles | `4.2M` | total across Thai Tourism Trends |
| Repeat Rate | `34%` | average per event |
| NPS Score | `72` | average per event |
| Active Campaigns | `18` | total across Thai Tourism Trends |
| Offer Conversion | `12.4%` | average per event |
| Upsell Revenue | `฿84M` | total across Thai Tourism Trends |
| App Engagement | `67%` | average per event |


## Demo flow

1. Executive Cockpit
2. Sentiment Intelligence
3. Guest Personalization
4. Ask AI
5. Architecture & Data

## Talking points

- **0.72 sentiment** - portfolio average (down from 0.78 — declining trend)
- **342 guests** - in service recovery queue awaiting follow-up
- **200K reviews** - analyzed by AI_SENTIMENT across 4 languages
- **25,000 offers** - personalized recommendations generated for upcoming stays
- **7 properties** - showing declining NPS trends
- **฿95M** - personalization revenue opportunity (US$2.7M)

## Business impact

- Thailand's hotel industry generated ฿680B in revenue in 2023 from 28M international arrivals (TAT Thailand)
- Personalized guest experiences increase repeat booking rates by 20-40% (McKinsey Hospitality)
- Service recovery within 24 hours retains 70% of dissatisfied guests vs 30% without (Harvard Business Review)
- AI-driven sentiment analysis improves guest satisfaction scores by 8-12 NPS points (Deloitte Hospitality)

---
Generated from `generator/demo_specs/aws-thailand-tourism-guest-360.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-thailand-tourism-guest-360` instead.
