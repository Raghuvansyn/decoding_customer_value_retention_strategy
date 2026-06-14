# Implementation Roadmap

> **Source docs:** `project_analysis.md` · `feature_engineering_strategy.md` · `loyalty_framework.md`  
> **Execution order:** Python → SQL → Power BI. Each phase depends on the output of the previous.

---

## Phase 1 — Python Workflow

### Step 1.1 · Data Cleaning

| | Detail |
|---|---|
| **Input** | `data/Dataset (1).csv` |
| **Output** | `data/cleaned.csv` |
| **Tasks** | Drop `Promo Code Used` (100% collinear with `Discount Applied`). Impute 37 missing `Review Rating` values with category-level median. Standardise all column names to snake_case. Validate no remaining nulls. |
| **Dependency** | None — first step in chain. |

---

### Step 1.2 · Feature Engineering

| | Detail |
|---|---|
| **Input** | `data/cleaned.csv` |
| **Output** | `data/features.csv` |
| **Tasks** | Compute all 11 features from `feature_engineering_strategy.md`: `tenure_score`, `discount_dependent`, `subscription_flag`, `loyalty_score_A`, `loyalty_score_B`, `value_tier`, `satisfaction_flag`, `frequency_score`, `high_value_confirmed`, `promo_sunset_candidate`, `geo_demand_type`. |
| **Dependency** | Step 1.1 complete. |

**Feature build order** (respects internal dependencies):

```
tenure_score          ← Previous Purchases
discount_dependent    ← Discount Applied
subscription_flag     ← Subscription Status
loyalty_score_A       ← tenure_score
loyalty_score_B       ← tenure_score + subscription_flag + discount_dependent
value_tier            ← loyalty_score_B
satisfaction_flag     ← Review Rating (post-imputation)
frequency_score       ← Frequency of Purchases
high_value_confirmed  ← loyalty_score_B + frequency_score
promo_sunset_candidate← discount_dependent + subscription_flag + Previous Purchases
geo_demand_type       ← Location + discount_dependent (aggregated per state)
```

---

### Step 1.3 · Framework A vs. Framework B Sensitivity Test

| | Detail |
|---|---|
| **Input** | `data/features.csv` |
| **Output** | `reports/framework_sensitivity.csv` |
| **Tasks** | Recompute `loyalty_score_B` at weights (60/25/15) and (40/35/25). Compare tier membership changes vs. baseline (50/30/20). Report % of customers who shift tier. Validate weights (shifts of 9.1% under a tenure-heavy model and 14.6% under a subscription-heavy model). |
| **Dependency** | Step 1.2 complete. |

---

### Step 1.4 · Exploratory Summary

| | Detail |
|---|---|
| **Input** | `data/features.csv` |
| **Output** | `reports/eda_summary.csv` |
| **Tasks** | Segment-level breakdowns: avg `Purchase Amount`, avg `Previous Purchases`, discount rate, subscription rate, satisfaction distribution — grouped by `value_tier`, `geo_demand_type`, `Category`, `Season`, `Age` band. These become the data tables SQL queries will be validated against. |
| **Dependency** | Step 1.2 complete. |

---

### Python Deliverables Summary

| File | Description |
|---|---|
| `data/cleaned.csv` | Raw data after null treatment and column drop |
| `data/features.csv` | Full enriched dataset — 18 original + 11 engineered columns |
| `reports/framework_sensitivity.csv` | Weight sensitivity test results for Framework B |
| `reports/eda_summary.csv` | Segment-level descriptive stats for validation |

---

## Phase 2 — SQL Workflow

> **Assumption:** `features.csv` is loaded into a local database (SQLite / PostgreSQL) as table `customer_features`.  
> All queries are standalone `.sql` files. Each file maps directly to one of the five business questions from the brief.

---

### Step 2.1 · Base View

| | Detail |
|---|---|
| **Input** | `customer_features` table (from `data/features.csv`) |
| **Output** | SQL view `v_customer_base` |
| **File** | `sql/00_base_view.sql` |
| **Tasks** | Create a reusable view with all columns + computed `age_band` (`CASE` on Age: 18–29, 30–44, 45–59, 60–70). All subsequent queries reference this view, not the raw table. |
| **Dependency** | Phase 1 complete; `features.csv` loaded. |

---

### Step 2.2 · Q1 — Loyal vs. Promo Buyers

| | Detail |
|---|---|
| **Input** | `v_customer_base` |
| **Output** | Result set: avg previous purchases, avg spend, satisfaction rate, subscription rate — segmented by `discount_dependent` and `value_tier` |
| **File** | `sql/Q1_loyal_vs_promo_buyers.sql` |
| **Tasks** | Validate the core hypothesis: do promo buyers and non-promo buyers differ on loyalty signals? Quantify the gap. |
| **Dependency** | Step 2.1. |

---

### Step 2.3 · Q2 — Behavioural Value Predictors

| | Detail |
|---|---|
| **Input** | `v_customer_base` |
| **Output** | Result set: `loyalty_score_B` average by `age_band`, `frequency_score` band, `Category`, `Payment Method` |
| **File** | `sql/Q2_value_predictors.sql` |
| **Tasks** | Identify which demographic and behavioural variables correlate with high `value_tier`. Feeds ICP construction. |
| **Dependency** | Step 2.1. |

---

### Step 2.4 · Q3 — Geographic Opportunity

| | Detail |
|---|---|
| **Input** | `v_customer_base` |
| **Output** | Result set: per-state customer count, avg `Purchase Amount`, discount rate, `geo_demand_type` label |
| **File** | `sql/Q3_geo_opportunity.sql` |
| **Tasks** | Rank states by `geo_demand_type`. Identify "Organic Pull" states for brand investment and "Discount Pull" states for promo reduction. |
| **Dependency** | Step 2.1. |

---

### Step 2.5 · Q4 — Promo Restructure Targets

| | Detail |
|---|---|
| **Input** | `v_customer_base` |
| **Output** | Result set: count of `promo_sunset_candidate = 1` by state, age band, category; avg `loyalty_score_B`; avg spend |
| **File** | `sql/Q4_promo_restructure.sql` |
| **Tasks** | Profile the sunset candidate segment in full. Outputs feed the retention playbook's segment naming, timeline, and metric selection. |
| **Dependency** | Step 2.1. |

---

### Step 2.6 · Q5 — Ideal Customer Profile

| | Detail |
|---|---|
| **Input** | `v_customer_base` |
| **Output** | Result set: multi-variable profile of customers where `value_tier = 'Champion'` AND `high_value_confirmed = 1` |
| **File** | `sql/Q5_ideal_customer_profile.sql` |
| **Tasks** | Aggregate modal values for: `age_band`, `Gender`, `Category`, `Shipping Type`, `Payment Method`, `Season`, `satisfaction_flag`, `frequency_score`. Output is the data-backed ICP the marketing team receives. |
| **Dependency** | Step 2.1. |

---

### SQL Deliverables Summary

| File | Maps To |
|---|---|
| `sql/00_base_view.sql` | Foundation for all queries |
| `sql/Q1_loyal_vs_promo_buyers.sql` | Business question 1 |
| `sql/Q2_value_predictors.sql` | Business question 2 |
| `sql/Q3_geo_opportunity.sql` | Business question 3 |
| `sql/Q4_promo_restructure.sql` | Business question 4 |
| `sql/Q5_ideal_customer_profile.sql` | Business question 5 |

Each query output is exported as a `.csv` to `reports/sql_outputs/` for Power BI ingestion.

---

## Phase 3 — Power BI Workflow

> **Input:** Six `.csv` files from `reports/sql_outputs/` + `data/features.csv`  
> **Output:** One `.pbix` file with four dashboard panels  
> **Dependency:** Phase 2 complete; all SQL exports available.

---

### Step 3.1 · Data Model

| | Detail |
|---|---|
| **Input** | `data/features.csv` (fact table) + Q1–Q5 output CSVs (summary tables) |
| **Output** | Star schema inside Power BI — one fact table, five summary tables as dimension/aggregation layers |
| **File** | `powerbi/customer_dashboard.pbix` (data model tab) |
| **Tasks** | Load all CSVs. Define relationships on `Customer ID` and `Location`. Confirm column types. No DAX measures needed if SQL aggregations are pre-built correctly. |
| **Dependency** | All SQL outputs exported. |

---

### Step 3.2 · Panel 1 — Customer Pyramid

| | Detail |
|---|---|
| **Input** | Q5 output + `features.csv` `value_tier` column |
| **Visual** | Stacked bar or funnel: Champion / Growth / Casual as % of total customers, with avg spend per tier overlaid |
| **Dependency** | Step 3.1. |

---

### Step 3.3 · Panel 2 — Promo Dependency vs. Retention

| | Detail |
|---|---|
| **Input** | Q1 output (`discount_dependent` × `value_tier` cross-tab) |
| **Visual** | Scatter plot: X = discount rate by segment · Y = avg `Previous Purchases` · Bubble size = customer count · Colour = `value_tier` |
| **Key message** | If discount rate and loyalty score are uncorrelated (or positively correlated), the promo programme is confirmed non-effective. |
| **Dependency** | Step 3.1. |

---

### Step 3.4 · Panel 3 — Geographic Opportunity Map

| | Detail |
|---|---|
| **Input** | Q3 output (state-level `geo_demand_type`, avg spend, discount rate) |
| **Visual** | US filled map choropleth — 3 colours: Organic Pull (green), Discount Pull (amber), Underdeveloped (grey) |
| **Dependency** | Step 3.1. Power BI built-in US state geocoding — no custom shapefile needed. |

---

### Step 3.5 · Panel 4 — Category Funnel

| | Detail |
|---|---|
| **Input** | Q2 output (avg `Previous Purchases` and `loyalty_score_B` by `Category` and `Item Purchased`) |
| **Visual** | Horizontal bar chart sorted by avg Previous Purchases ascending — low bars = entry categories, high bars = retention categories |
| **Key message** | Identifies which categories attract new buyers vs. which ones anchor long-tenure customers. |
| **Dependency** | Step 3.1. |

---

### Power BI Deliverables Summary

| File | Description |
|---|---|
| `powerbi/customer_dashboard.pbix` | Four-panel founder dashboard (single file) |

---

## Full Dependency Chain

```
Dataset (1).csv
    │
    ▼ Step 1.1
cleaned.csv
    │
    ▼ Step 1.2
features.csv ──────────────────────────────────────────┐
    │                                                   │
    ▼ Step 1.3              ▼ Step 1.4                  │
framework_sensitivity.csv  eda_summary.csv             │
                                                        │
                            ┌───────────────────────────┘
                            ▼ Step 2.1
                        v_customer_base (SQL view)
                            │
              ┌─────────────┼─────────────────────────┐
              ▼             ▼             ▼            ▼
           Q1.sql        Q2.sql       Q3.sql       Q4.sql  Q5.sql
              │             │             │            │       │
              └─────────────┴─────────────┴────────────┴───────┘
                                    │
                          reports/sql_outputs/*.csv
                                    │
                                    ▼ Step 3.1
                           Power BI Data Model
                                    │
                    ┌───────────────┼──────────────┐
                    ▼               ▼              ▼
               Panel 1          Panel 2      Panel 3 + 4
                                    │
                          customer_dashboard.pbix
```

---

## File Structure

```
decoding_customer_value/
├── data/
│   ├── Dataset (1).csv          ← source (read-only)
│   ├── cleaned.csv              ← Phase 1 output
│   └── features.csv             ← Phase 1 output
├── docs/
│   ├── project_analysis.md
│   ├── feature_engineering_strategy.md
│   ├── loyalty_framework.md
│   └── implementation_roadmap.md
├── reports/
│   ├── framework_sensitivity.csv
│   ├── eda_summary.csv
│   └── sql_outputs/
│       ├── Q1_loyal_vs_promo_buyers.csv
│       ├── Q2_value_predictors.csv
│       ├── Q3_geo_opportunity.csv
│       ├── Q4_promo_restructure.csv
│       └── Q5_ideal_customer_profile.csv
├── sql/
│   ├── 00_base_view.sql
│   ├── Q1_loyal_vs_promo_buyers.sql
│   ├── Q2_value_predictors.sql
│   ├── Q3_geo_opportunity.sql
│   ├── Q4_promo_restructure.sql
│   └── Q5_ideal_customer_profile.sql
├── notebooks/
│   └── feature_engineering.ipynb
└── powerbi/
    └── customer_dashboard.pbix
```
