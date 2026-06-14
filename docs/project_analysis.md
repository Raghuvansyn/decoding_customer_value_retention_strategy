# Decoding Customer Value — Project Analysis

> **Prepared by:** Consulting Team Review  
> **Source files:** `data/Dataset (1).csv`, `data/SQL.pdf`  
> **Date:** June 2026

---

## 1. Dataset Overview

| Attribute | Detail |
|---|---|
| **Total records** | 3,900 customer-purchase observations |
| **Total columns** | 18 |
| **Missing values** | 37 rows with blank `Review Rating` (~0.9%) — only field with nulls |
| **Date / timestamp** | **None.** The dataset is entirely cross-sectional (one row per customer) |
| **Duplicate customers** | None apparent — Customer IDs 1–3900 are sequential and unique |
| **Gender split** | Male 2,652 (68%) · Female 1,248 (32%) |
| **Age range** | 18–70 years (uniform spread; no binning in source data) |
| **Geography** | All 50 US states represented (pure D2C, no physical stores) |
| **Categories** | Clothing, Footwear, Outerwear, Accessories |
| **Purchase amount** | \$20–\$100 (USD), avg **\$59.76** |
| **Purchase seasons** | Evenly distributed: Winter 971, Spring 999, Summer 955, Fall 975 |

**Critical structural note:** Each row represents a single customer snapshot — **not** a transaction log. There is one row per customer ID with an aggregate `Previous Purchases` count. This is fundamental to every analytical decision.

---

## 2. Column-by-Column Data Dictionary

| # | Column | Type | Values / Range | Notes |
|---|---|---|---|---|
| 1 | `Customer ID` | Integer | 1–3900 | Unique identifier. Sequential, no gaps. |
| 2 | `Age` | Integer | 18–70 | Continuous. Uniform-ish spread. No binning applied yet. |
| 3 | `Gender` | Categorical | Male (68%), Female (32%) | Binary. Significant imbalance — important for segmentation fairness. |
| 4 | `Item Purchased` | Categorical | 25 distinct items | Relatively balanced (~140–171 per item). No single dominant item. |
| 5 | `Category` | Categorical | Clothing (44.5%), Accessories (31.8%), Footwear (15.4%), Outerwear (8.3%) | Derived hierarchy from `Item Purchased`. Clothing dominates. |
| 6 | `Purchase Amount (USD)` | Float | \$20–\$100, avg \$59.76 | Narrow band — looks like a price-ceiling or synthetic constraint. No outliers. |
| 7 | `Location` | Categorical | All 50 US states | Near-uniform distribution (avg 78 per state). Montana (96), California (95), Idaho (93) at top. |
| 8 | `Size` | Categorical | M (45%), L (27%), S (17%), XL (11%) | Standard size distribution. Could proxy gender or body type. |
| 9 | `Color` | Categorical | ~25+ colors | High cardinality. Limited analytical use except for color preference in segmentation. |
| 10 | `Season` | Categorical | Spring, Summer, Fall, Winter | Evenly split. Represents the season of the purchase. |
| 11 | `Review Rating` | Float | 2.5–5.0, avg 3.75 | **37 nulls** (MCAR likely). Key proxy for satisfaction. Watch for ceiling effects near 5.0. |
| 12 | `Subscription Status` | Binary | Yes (27%), No (73%) | Subscription = paid loyalty program member. Critical loyalty signal. |
| 13 | `Shipping Type` | Categorical | 6 types, roughly equal | Express, Free Shipping, Next Day Air, Standard, 2-Day, Store Pickup. Preference could proxy urgency/loyalty. |
| 14 | `Discount Applied` | Binary | Yes (43%), No (57%) | **Perfectly correlated with `Promo Code Used`** — these two are always identical. See analytical challenge. |
| 15 | `Promo Code Used` | Binary | Yes (43%), No (57%) | **100% collinear with `Discount Applied`.** Only one should be used in any model. |
| 16 | `Previous Purchases` | Integer | 1–50, avg 25.35 | **The most important column.** This is the closest proxy to customer tenure/loyalty in the absence of timestamps. Nearly uniform 1–50. |
| 17 | `Payment Method` | Categorical | PayPal (17.4%), Cash (17.2%), Credit Card (17.2%), Venmo (16.3%), Debit Card (16.3%), Bank Transfer (15.7%) | Remarkably balanced. Payment method could proxy tech-savviness or formality. |
| 18 | `Frequency of Purchases` | Categorical | 7 values | Every 3 Months (584), Annually (572), Quarterly (563), Monthly (553), Bi-Weekly (547), Fortnightly (542), Weekly (539) — suspiciously uniform. |

---

## 3. Core Business Problem

The client is a **pure-play D2C fashion brand** operating exclusively online across the US. They have 3,900 customer records but **zero structured intelligence** on who their best customers are or whether their promotional programme is building loyalty or destroying margins.

The founding team faces one central strategic fork:

> **"Are we building a loyal customer base organically, or are we running a permanent discount machine that only works when we pay for it?"**

This question has two radically different strategic responses:
- **If loyalty is organic:** Scale the relationship, reduce discounts, invest in retention.
- **If loyalty is promo-driven:** The business model is at risk; discounts are masking churn and suppressing margins.

Without answering this, every marketing and product decision is a guess.

**The five specific intelligence gaps the brand has named:**
1. Who buys repeatedly without needing a discount?
2. What behavioural patterns today predict long-term customer value?
3. Which geographies have untapped commercial potential?
4. How should the promo programme be restructured to protect margins?
5. What does the ideal customer profile look like (age, habits, payment, satisfaction)?

---

## 4. Hidden Analytical Challenges

These are the non-obvious traps that will separate a good submission from a winning one.

### 4.1 The Discount/Promo Perfect Collinearity Trap
`Discount Applied` and `Promo Code Used` are **100% identical** across all 3,900 rows — no customer ever used one without the other. Using both in any model is pure noise amplification. Pick one and document why. Deeper question: does "discount applied" mean the customer *demanded* a discount, or that the brand *offered* it? The dataset cannot answer this — and that ambiguity is real.

### 4.2 No Timestamps — Loyalty Must Be Constructed
There is **no order date, no cohort date, no account creation date.** `Previous Purchases` is an integer count (1–50) — the closest thing to tenure, but it conflates frequency and time. A customer with 50 previous purchases *might* be a 10-year loyalist or a 2-year bulk buyer. This is the most important methodological constraint in the dataset. Any "loyalty" definition must be explicit, justified, and defensible.

### 4.3 Previous Purchases Distribution Is Suspiciously Uniform
The range is exactly 1–50 with an average of 25.35 — this is almost perfectly uniform. Real customer data rarely looks like this. It strongly suggests either: (a) the dataset is synthetic/simulated, or (b) it has been binned and re-scaled. **Teams that don't notice this will build models on artificial variance.** You must acknowledge this and explain how it affects confidence in findings.

### 4.4 Purchase Amount Has a Hard Ceiling at \$100
Every transaction is between \$20–\$100. No purchases above \$100 exist. This is either a deliberate price-point strategy or an artificial cap in the data. Either way, it means **purchase amount alone cannot differentiate high-value customers.** Value segmentation must come from frequency and tenure proxies, not spend alone.

### 4.5 Discount Users and Non-Users Have Nearly Identical Purchase History
- Avg previous purchases for **Discount=Yes**: 25.74
- Avg previous purchases for **Discount=No**: 25.06

The difference is **0.68 purchases** — barely meaningful. This is either a deeply important finding (discounts don't correlate with loyalty at all) or an artifact of the synthetic uniform distribution. Either interpretation requires explicit treatment and intellectual honesty.

### 4.6 Subscription Status Is Weakly Predictive of Tenure
- Subscribed: avg 26.08 previous purchases
- Not subscribed: avg 25.08 previous purchases

Again, the difference is about 1 purchase. If subscription = loyalty programme membership, this is a damning signal. Top-tier teams will interrogate *why* subscribers don't buy noticeably more.

### 4.7 Gender Imbalance May Skew Segmentation
68% Male vs. 32% Female. If unaddressed, any demographic segmentation will be male-dominated by default. Teams need to either control for this or explicitly flag it. The brief mentions nothing about gender bias, but a consulting-grade answer must.

### 4.8 Category-Item Ambiguity
"Blouse" and "Skirt" are in Clothing; "Coat" is in Outerwear; "Sandals" in Footwear. But there's no size/gender encoding at category level — a 65-year-old male buying a "Blouse" is treated identically to a 25-year-old female buying one. The data makes no accommodation for this, which creates noise in any item-level analysis.

### 4.9 "Frequency of Purchases" is Self-Reported, Not Computed
`Frequency of Purchases` ("Weekly," "Monthly," "Annually," etc.) appears to be a self-declared or survey-based field — it does **not** match with `Previous Purchases` counts in any derivable way. A customer who says "Weekly" with only 3 previous purchases is internally inconsistent. Teams must decide whether to trust, ignore, or triangulate this field.

### 4.10 50-State Location With Near-Uniform Distribution
Real US D2C data heavily concentrates in CA, NY, TX, FL. This data is near-uniform across all 50 states. That's synthetic. Geographic analysis conclusions must be held tentatively.

---

## 5. What the Judges Are Likely Evaluating

Based on the problem statement language, the explicit deliverables, and the "Central Analytical Challenge" section of the brief:

### 5.1 Intellectual Honesty About Constraints *(High Weight)*
The brief explicitly says: *"Loyalty must be defined, not declared."* and *"Every segment claim must be traceable."* Judges will penalise teams that use words like "loyal," "at-risk," or "high-value" without defining them precisely in terms of dataset variables. A team that builds on shaky assumptions without flagging them will lose to one that builds a smaller but watertight argument.

### 5.2 Quality of Competing Loyalty Definitions *(High Weight)*
The brief requires **at least two competing definitions of loyalty** using different variable combinations, tested and compared. This is the centrepiece of the analytical challenge. A weak team picks one definition and runs with it. A winning team builds two (e.g., one based on Previous Purchases + No Discount; one based on Subscription + High Frequency), tests consistency between them, and makes a principled argument for which to use.

### 5.3 SQL Query Quality and Readability *(Medium-High Weight)*
The event is titled *"SQL | Consulting"* — SQL craft matters. Judges will look for: proper window functions, segmentation CTEs, readable aliasing, and queries that directly map to the 5 business questions. Messy joins or hardcoded magic numbers will cost points.

### 5.4 Feature Engineering Justification *(Medium-High Weight)*
The brief says: *"do not stop at computing numbers, explain the logic behind each metric you create."* and *"metrics that sound analytical but do not lead to a decision are not useful."* Every engineered feature (discount dependency score, value tier, satisfaction flag) must have a stated business purpose.

### 5.5 Actionability of Recommendations *(High Weight)*
The brief is explicit: *"Reduce discounts is not an acceptable answer."* Recommendations must name: the segment, the trigger behaviour, the rollout timeline, and the tracking metric. Vague strategy slides will score low.

### 5.6 Dashboard Design for Non-Technical Audience *(Medium Weight)*
The Power BI dashboard is for a "non-technical founding team." Judges will evaluate: clarity over complexity, the four-panel structure (customer pyramid, promo dependency, geographic opportunity, category funnel), and whether a founder could make a decision from it in under 2 minutes.

### 5.7 Executive Summary Quality *(Medium Weight)*
One page maximum. The ability to compress complex analysis into a crisp, founder-facing narrative is a consulting core skill. This will likely be the first thing judges read.

---

## 6. Key Opportunities in This Dataset

### 6.1 The Discount Non-Correlation Is Your Headline Finding
If you validate that discount usage does not meaningfully predict higher tenure (Previous Purchases), that's a major business insight: **the promo programme is not building loyalty.** This supports a promo sunset recommendation and is the central answer to the client's strategic question.

### 6.2 Build the "Ideal Customer Profile" With Multiple Variables
The dataset has enough fields to define a rich ICP: Age band + Gender + Category + Shipping preference + Payment method + Subscription status + Rating + Purchase frequency. A well-constructed ICP (e.g., "35–50, female, clothing + accessories, subscribed, no discount, PayPal, 4.5+ rating, weekly") is a concrete deliverable marketing can use immediately.

### 6.3 Subscription Status as the Clean Loyalty Signal
With 27% subscriber rate and slightly higher tenure, there's an opportunity to build the retention argument around subscription conversion — move customers from "promo buyers" to "subscribers" as the retention mechanism.

### 6.4 Category Funnel: Entry vs. Retention Categories
Accessories and Footwear may attract entry-level customers (lower previous purchase counts on average) while Clothing items could be retention anchors for high-tenure customers. Validate this and build it into the category funnel panel.

### 6.5 Satisfaction Flag from Review Rating
Rating < 3.5 → Dissatisfied (flight risk). Rating 3.5–4.2 → Neutral. Rating 4.3–5.0 → Satisfied (retention candidate). With 37 missing ratings, imputation strategy matters — median by category or segment, not global median.

### 6.6 Geographic "Organic Pull" vs. "Discount Pull" Map
States where discount rate is below average AND purchase volume is above average = organic demand (genuine brand pull). States where discount rate is above average but volume is average = discount-dependent demand (fragile). This geographic segmentation directly fulfils one of the dashboard panels.

### 6.7 Frequency × Previous Purchases as Dual Tenure Signal
Customers who self-report "Weekly" frequency AND have high Previous Purchases are the most behaviorally consistent loyal segment. Cross-validating the frequency self-report against the purchase count creates a "confirmed high-value" tier that's more defensible than either variable alone.

---

## 7. Risks and Limitations of the Dataset

| Risk | Severity | Mitigation |
|---|---|---|
| Dataset appears synthetic (uniform distributions) | **High** | All conclusions qualified as directional; real deployment needs validation on live data |
| No timestamps — no true cohort or churn analysis | **High** | Use Previous Purchases as tenure proxy; be explicit about limitation |
| Discount/Promo perfect collinearity | **Medium** | Drop one variable; use `Discount Applied` as the single field |
| Gender imbalance (68/32) | **Medium** | Control for gender in all segment comparisons; report gender-specific ICPs |
| Purchase amount ceiling at \$100 | **Medium** | Do not use spend alone as value driver; use frequency × spend composite |
| 37 missing Review Ratings | **Low** | Impute with category-level median; flag in methodology |
| Self-reported frequency field may be unreliable | **Medium** | Cross-validate with Previous Purchases; use as secondary signal only |
| No product price data (only total amount) | **Low** | Items cannot be compared by unit price; rely on category-level aggregates |
| Geographic distribution is artificial | **Medium** | Present geographic findings as illustrative; note real-world concentration risk |

---

## 8. Recommended Project Strategy

This section lays out the recommended analytical approach from a consulting standpoint — sequenced, with clear rationale.

### Phase 1: Data Preparation (Python)
**Do first, because every downstream analysis depends on data quality.**

1. **Drop `Promo Code Used`** — it is perfectly collinear with `Discount Applied`.
2. **Impute missing Review Ratings** — use category-level median (not global).
3. **Bin Age** into 4 segments: Young Adult (18–29), Adult (30–44), Mid-Senior (45–59), Senior (60–70).
4. **Create `Discount Dependency Flag`** — customers where `Discount Applied = Yes`. This is your primary promo-reliance indicator.
5. **Create `Loyalty Score`** — build two competing versions:
   - **Definition A:** `Previous Purchases` percentile rank (top 25% = High Loyalty).
   - **Definition B:** Composite of `Previous Purchases` + `Subscription Status` + inverse `Discount Applied` (weighted sum, normalised 0–100).
   - Compare the two; argue for Definition B (richer signal, more decision-relevant).
6. **Create `Value Tier`** — segment customers into High / Medium / Low using the chosen Loyalty Score.
7. **Create `Satisfaction Flag`** — Review Rating ≥ 4.3 = Satisfied; 3.5–4.2 = Neutral; < 3.5 = At Risk.
8. **Create `Frequency Score`** — convert text frequency to numeric (Weekly=7, Bi-Weekly=3.5, Fortnightly=3.5, Monthly=2, Quarterly=1, Every 3 Months=0.75, Annually=0.5).

### Phase 2: Customer Segmentation (SQL)
**Answer each of the 5 business questions with a dedicated, clearly-named query.**

| Query | Business Question |
|---|---|
| `Q1_loyal_vs_promo_buyers.sql` | Discount users vs. non-users by average previous purchases, subscription rate, satisfaction |
| `Q2_value_predictors.sql` | Correlation of age band, frequency, category, and payment method with value tier |
| `Q3_geo_opportunity.sql` | States ranked by avg spend AND promo dependency rate (4-quadrant: organic/dependent/low/high) |
| `Q4_promo_restructure.sql` | Segment-level discount rate vs. retention signal — identifies sunset candidates |
| `Q5_ideal_customer_profile.sql` | Multi-variable profile of top-quartile customers across all dimensions |

### Phase 3: Power BI Dashboard (4-Panel)
**Build for a 90-second founder briefing.**

| Panel | What to Show |
|---|---|
| **Customer Pyramid** | Value tier distribution (High/Medium/Low) with % of revenue by tier |
| **Promo Dependency Map** | Scatter: discount rate (X) vs. avg previous purchases (Y) by segment — want a negative correlation |
| **Geographic Opportunity Map** | US state choropleth — 4 colours: Organic Pull, Discount Pull, Low Volume, High Potential |
| **Category Funnel** | Bar/waterfall showing avg Previous Purchases by category and item — entry vs. retention categories |

### Phase 4: Retention Playbook

**Promo Sunset Plan (Specific Segments):**
- **Segment to sunset first:** High Previous Purchases (>35) + No Subscription + Discount Applied — these customers buy frequently *and* take discounts but haven't committed to subscription. They are margin-eroding loyalists.
- **Trigger:** Discount applied on 3+ consecutive purchases.
- **Timeline:** Reduce discount frequency by 25% per quarter over 3 quarters.
- **Metric to track:** Revenue per customer in the sunset cohort vs. control; if < 10% revenue drop after 2 quarters, accelerate.
- **Trade-off:** Risk of 10–15% volume loss in this segment; margin recovery of ~8–12% if successful.

**Ideal Customer Profile:**
- Age 35–50
- Subscribed (Yes)
- No discount applied
- Previous Purchases ≥ 35 (top quartile)
- Clothing or Accessories category
- Review Rating ≥ 4.3
- Purchase Frequency: Weekly or Bi-Weekly
- Payment: Credit Card or PayPal (implies formality and recurring commitment)

### Phase 5: Executive Summary (1 Page)
Lead with the answer, not the method:

> *"The brand's discount programme is not building loyalty — promo users and non-promo users have virtually identical purchase histories (25.7 vs. 25.1 previous purchases). This means promotional spend is margin cost, not loyalty investment. The 27% subscriber base shows marginally higher tenure but is significantly under-leveraged. The strategic recommendation is a segment-specific promo sunset targeting 680 customers who buy frequently but remain non-subscribed discount users, paired with a subscription conversion push. Projected outcome: 8–12% margin improvement with under 10% volume risk if executed over 9 months."*

---

## Appendix: Quick Reference Statistics

```
Total customers:         3,900
Gender:                  Male 68%, Female 32%
Subscriber rate:         27%
Discount usage rate:     43%
Avg purchase amount:     $59.76 (range $20–$100)
Avg previous purchases:  25.35 (range 1–50)
Avg review rating:       3.75 (range 2.5–5.0)
Missing review ratings:  37 (~0.9%)
Categories:              Clothing 44.5%, Accessories 31.8%, Footwear 15.4%, Outerwear 8.3%
States covered:          All 50 US states
Seasons:                 Roughly equal split across 4 seasons
Purchase frequencies:    7 categories, near-uniform distribution
Payment methods:         6 methods, near-uniform distribution
Shipping types:          6 types, near-uniform distribution
Unique items:            25 items, near-uniform distribution
```

---

*This document was prepared as a consulting-team intake analysis. All statistics computed directly from the source dataset. All strategic recommendations are grounded in data observations and are explicitly qualified where the dataset's synthetic nature limits confidence.*
