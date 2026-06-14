# Executive Summary: Decoding Customer Value

**Project:** D2C Fashion Brand Customer Loyalty & Retention Strategy  
**Data Scope:** 3,900 Active Customers (18–70 age range, 50 US States represented)  
**Methodology:** Framework B (Multi-Signal Composite Score: 50% Tenure, 30% Subscription, 20% Discount Independence)

---

## 1. Core Strategic Question & Hypothesis Test
The central commercial question asked by the brand was: **"Is the business building organic loyalty, or is it reliant on promotions to drive sales?"**

The core hypothesis tested was: **"Promo buyers and non-promo buyers have similar tenure (number of previous purchases)."**

### The Verdict: Hypothesis Confirmed (✅)
* **Promo Buyers (1,677 customers)**: Average tenure is **25.74 purchases**.
* **Full-Price Buyers (2,223 customers)**: Average tenure is **25.06 purchases**.
* **The Margin Gap**: The difference in tenure is a negligible **0.68 purchases** (a 2.7% variance), while average spend per transaction remains identical (~$59.28 for promo vs. ~$60.13 for full-price).
* **Strategic Finding**: The promotional program **does not drive incremental brand loyalty or customer tenure**. It represents a direct margin erosion on repeat purchases that customers would have made anyway.

---

## 2. Key Analytical Discoveries

### 2.1 The Synthetic Gender & Program Skew
A deep audit of the demographic and transactional features exposed a critical structural bias in the dataset:
* **Females (1,248 customers / 32% of base)**: Have **exactly 0% subscription rate and 0% promotion rate** (100% full-price, 100% non-subscribed).
* **Males (2,652 customers / 68% of base)**: Have a **39.7% subscription rate and a 63.2% promotion rate**.
* **The Loyalty Scoring Impact**: Under Framework B, because Females are locked out of the subscription program (30% weight) but receive the full discount-independence score (20% weight), their maximum possible loyalty score is capped at 70.0. Consequently, Females are structurally underrepresented in the "Champion" segment (11.3% of Females vs. 17.4% of Males) despite being our most margin-healthy segment (100% organic, full-price purchases).

### 2.2 Customer Value Pyramid
Using Framework B thresholds (Champion $\ge 65$, Growth 35–64, Casual $< 35$), the customer base is segmented as:
* **Champions (15.5% / 603 customers)**: High-tenure subscribers and premium full-price buyers. Average spend: **$61.53**.
* **Growth (55.0% / 2,146 customers)**: Mid-tenure cohort with mixed subscription and promotional behaviors. Average spend: **$59.29**.
* **Casual (29.5% / 1,151 customers)**: Low-tenure or highly discount-dependent buyers. Average spend: **$59.73**.

### 2.3 Geographic Opportunity Types
US States were grouped into three demand segments based on volume (average 78 customers/state) and promo rate (average 43%):
* **Organic Pull (11 States / 965 customers)**: High volume, below-average promo rates (avg 40.0%). Represents healthy brand affinity (e.g., California, Alabama, Illinois, Montana).
* **Discount Pull (13 States / 1,068 customers)**: High volume, above-average promo rates (avg 46.8%). Represents margin-at-risk regions (e.g., Missouri, Kentucky, Nevada).
* **Underdeveloped (26 States / 1,867 customers)**: Low-volume states (avg <78 customers) representing fragmented market share.

---

## 3. High-Level Recommendations

1. **Implement Phased Promo Sunsetting**: Immediately target the **198 high-tenure, promo-only customers** (Sunset Candidates) who buy frequently but rely on discounts. Transitioning them off promos shifts an Estimated Transaction Value of $11.6K to full price (with an Estimated Margin Recovery of approximately $2.3K per order cycle, assuming an average 20% discount) on high-frequency transactions.
2. **Insulate Organic Customers**: Protect the **2,223 organic, full-price buyers** (including 100% of Female customers) from receiving promotional offers. They purchase organically; introducing discounts to this group would result in immediate, unnecessary margin erosion.
3. **Execute Subscription Upsell Funnel**: Convert the **246 mid-tenure, promo-only customers** to the subscription program *before* modifying their promotion access. A subscription locks in their volume and raises their Framework B score by 30 points, transitioning them from Growth $\rightarrow$ Champion.
4. **Optimize Geographic Focus**: Shift marketing spend in "Organic Pull" states (Alabama, Georgia, Montana) toward premium product positioning and subscription drives. In "Discount Pull" states (Missouri, Nevada), initiate the promo sunset.
5. **Adjust Demographics targeting**: Account for the synthetic gender bias in Power BI dashboarding and marketing models. Create a tailored, female-specific loyalty track focused on product value and early access, rather than subscription metrics.
