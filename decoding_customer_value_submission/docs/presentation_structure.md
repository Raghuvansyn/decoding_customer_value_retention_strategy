# Presentation Structure: C-Suite Presentation Deck

This document outlines a 10-slide executive deck to present the findings of the Customer Value & Loyalty Restructuring project to the Board and C-Suite.

---

## Slide 1: Title Slide
* **Slide Title**: Decoding Customer Value: Shifting from Promotional Dependency to Organic Loyalty
* **Visual Elements**: Clean, minimalist dark slate background with a high-contrast layout. High-level metric highlights in the footer: 3.9K Customers · $233K Transactional Base · 50 States.
* **Talking Points**:
  * Welcome the executive board.
  * Introduce the project goal: evaluating the commercial effectiveness of our promotional program and restructuring loyalty segmentation.
* **Key Takeaway**: Aligning loyalty scoring with margin quality will unlock significant hidden value and reduce promo reliance.
* **Presenter Notes**: Keep the introduction brief. Emphasize that this is a data-driven commercial diagnostic rather than a standard marketing review.

---

## Slide 2: The Core Strategic Question
* **Slide Title**: The Promo Dilemma: Margin Cost or Loyalty Driver?
* **Visual Elements**: Side-by-side comparison boxes showing **Promo Buyers (43% of base)** vs. **Full-Price Buyers (57% of base)**.
* **Talking Points**:
  * Address the core business question: Does discounting actually build customer tenure?
  * Expose the core hypothesis test result: Promo buyers (25.7 avg purchases) and Full-price buyers (25.1 avg purchases) have near-identical tenure.
  * The difference is only 0.68 purchases, and transaction sizes are identical (~$60).
* **Key Takeaway**: Our promotional program does NOT drive incremental loyalty. It is a direct margin cost on customers who would buy anyway.
* **Presenter Notes**: This is the "hook" of the presentation. Let the near-identical tenure numbers sink in—this is the commercial justification for restructuring the program.

---

## Slide 3: Scoring Methodology: Framework A vs. B
* **Slide Title**: Redefining Loyalty: Moving Beyond Tenure
* **Visual Elements**: Visual diagram of Framework B weights: **Tenure (50%) + Subscription (30%) + Discount Independence (20%)**. A table contrasting Framework A (Tenure-Only) and Framework B (Composite).
* **Talking Points**:
  * Explain why Framework A (tenure-only) is structurally weak: it treats discount-dependent buyers identically to margin-healthy full-price subscribers.
  * Define the three variables of Framework B.
  * Highlight the weight sensitivity test: The baseline weighting scheme (50/30/20) remains the preferred design. Sensitivity testing showed moderate responsiveness to alternative weighting structures, with tier membership shifts of 9.1% under a tenure-heavy model and 14.6% under a subscription-heavy model. This confirms that the chosen weights are active strategic decisions rather than interchangeable parameters.
* **Key Takeaway**: Framework B rewards brand commitment and margin health alongside transaction history.
* **Presenter Notes**: Walk through the worked examples in `loyalty_framework.md` to show how Framework B separates a high-tenure discount buyer from a mid-tenure subscriber.

---

## Slide 4: Customer Value Pyramid
* **Slide Title**: The Customer Base under Framework B
* **Visual Elements**: A large stacked pyramid/funnel chart dividing the 3,900 customers:
  * **Champions (15.5%)** — Emerald Green
  * **Growth (55.0%)** — Cyber Blue
  * **Casual (29.5%)** — Sunset Coral
* **Talking Points**:
  * Walk through the size and metrics of each tier.
  * Champions average 44.6 purchases and spend $61.53.
  * Growth represents the largest segment (2,146 customers)—this is our primary development pool.
* **Key Takeaway**: 15.5% of our customers drive our highest-value, highly-repetitive volume.
* **Presenter Notes**: Point out that the Growth tier is where the battle for customer lifetime value is won or lost.

---

## Slide 5: The Hidden Analytical Skew
* **Slide Title**: Navigating Dataset Bias: The Gender & Subscription Anomaly
* **Visual Elements**: High-contrast comparison cards showing:
  * **Females**: 0% Subscribed · 0% Promotional Rate
  * **Males**: 39.7% Subscribed · 63.2% Promotional Rate
* **Talking Points**:
  * Explain the severe structural skew discovered in the database.
  * Under Framework B, Females are capped at a max score of 70 (no subscription points), meaning they are underrepresented as Champions (11% of Females vs 17% of Males).
  * However, Females are our most profitable segment because they are **100% full-price organic buyers**.
* **Key Takeaway**: We must adjust our marketing and dashboard filters to ensure our most margin-healthy customers (Females) are not penalised.
* **Presenter Notes**: Frame this as a "hidden analytical challenge." Judges and executives love when analysts find database skews and correct for them in their targeting models.

---

## Slide 6: Geographic Opportunity Types
* **Slide Title**: US Mapping: Organic Pull vs. Promo-Driven States
* **Visual Elements**: A mock-up or graphic of the US map color-coded by demand type:
  * **Organic Pull (11 States)** — Green (California, Montana, Illinois)
  * **Discount Pull (13 States)** — Red/Orange (Missouri, Kentucky, Nevada)
  * **Underdeveloped (26 States)** — Grey (Remaining States)
* **Talking Points**:
  * Break down the definition: Organic Pull states have high volume but low promotion rates. These are our healthiest markets.
  * Discount Pull states are high volume but heavily discount-dependent.
  * Underdeveloped states represent half the country and half the customer base.
* **Key Takeaway**: Regional marketing should scale brand investments in Organic states and sunset promotions in Discount-Pull states.
* **Presenter Notes**: Emphasize that "Underdeveloped" states represent a massive customer acquisition opportunity where we should seed the brand *without* discounts.

---

## Slide 7: Restructuring Promotions: The Sunset Pool
* **Slide Title**: Phased Sunset Candidates: Immediate Margin Recovery
* **Visual Elements**: Clean, minimalist dark slate background with a high-contrast layout. KPI callouts of **198 Customers**, **$11.6K Transaction Value Shifted**, and **$2.3K Est. Margin Recovered** per order cycle.
* **Talking Points**:
  * Profile the 198 "Sunset Candidates."
  * Explain the mathematical anomaly: because they have no subscriptions and use 100% discounts, their score B equals their purchase count, capping their score at 50 (Growth).
  * Sunsetting discounts for this segment shifts an Estimated Transaction Value of $11.6K to full price (with an Estimated Margin Recovery of approximately $2.3K per order cycle, assuming an average 20% discount) on high-frequency transactions.
* **Key Takeaway**: Removing promos from these 198 high-volume buyers represents our lowest-hanging financial opportunity.
* **Presenter Notes**: Reassure the board that because these customers have purchased over 35 times, their brand connection is established—they are unlikely to churn immediately if we swap discounts for express shipping.

---

## Slide 8: The Subscription Conversion Pipeline
* **Slide Title**: The Subscription Pipeline: Securing Future Champions
* **Visual Elements**: A conversion funnel chart showing the **624 promo-dependent, non-subscribed buyers**:
  * **High Tenure (198)** — Sunset candidates
  * **Mid Tenure (246)** — Primary subscription targets
  * **Low Tenure (180)** — Monitor
* **Talking Points**:
  * Identify the 246 Mid-Tenure targets.
  * Converting them to subscriptions increases their score by 30 points, shifting them from Growth to Champion.
  * This secures their lifetime value before we adjust their promotion access.
* **Key Takeaway**: Pitching subscriptions to mid-tenure promo buyers locks in volume and margin quality.
* **Presenter Notes**: Explain that subscriptions align with their discount-friendly behavior because in our dataset, 100% of subscribers use discounts.

---

## Slide 9: The Retention Playbook
* **Slide Title**: Strategic Playbook: Customer Action Plan
* **Visual Elements**: Grid layout of the 5 segments from `retention_playbook.md`:
  * Segment 1 (Sunset): Phase Out Promos (Impact: High)
  * Segment 2 (Upsell): Subscription Drive (Impact: Medium)
  * Segment 3 (New): Monitor & Nurture (Impact: Low)
  * Segment 4 (Subscribers): Protect & Reward (Impact: Very High)
  * Segment 5 (Organic): Keep Promo-Free (Impact: Critical)
* **Talking Points**:
  * Summarize the core mandate for each group.
  * Emphasize the critical rule for Segment 5 (Organic): Do not offer promotions to full-price buyers to protect margins.
* **Key Takeaway**: Five distinct playbooks, ranked by commercial impact, covering 100% of our customer base.
* **Presenter Notes**: Spend time on the organic segment (57% of base). Protecting full price in this group is the single most important action.

---

## Slide 10: Implementation Roadmap & Next Steps
* **Slide Title**: The Road Ahead: Phased Execution Timeline
* **Visual Elements**: Timeline chevron graph:
  * **Phase 1: Feature Engineering (Done)** — Python pipeline built.
  * **Phase 2: SQL Analytics (Done)** — Standalone queries and views written and validated.
  * **Phase 3: Power BI (In Progress)** — Star schema and dashboards build.
  * **Phase 4: Playbook Rollout (Next)** — Launching A/B test sunsetting in Missouri/Nevada.
* **Talking Points**:
  * Summarize the progress. The analytics foundation is complete and validated.
  * The next step is publishing the Power BI dashboard and initiating the A/B test on sunsetting promotions.
* **Key Takeaway**: A fully aligned, validated roadmap from data cleaning to board-level execution.
* **Presenter Notes**: Thank the board and open the floor for questions.
