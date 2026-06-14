# Retention Playbook: Customer Restructure & Margin Recovery

This playbook translates the insights from Framework B and the SQL analytics layer into a structured retention strategy.

---

## 1. Segment Strategy Matrix

The customer base is classified into five mutually exclusive segments, each mapped to a specific operational action, risk level, and business impact.

| Segment | Volume (%) | Primary Action | Rationale | Business Impact | Risk Level |
|---|---|---|---|---|---|
| **1. Phased Sunset Candidates** | 198 (5.1%) | **Phased Promo Sunset** | High tenure (avg 43.2 purchases) non-subscribed promo buyers. Highly loyal but margin-eroding. | **HIGH** | Medium |
| **2. Subscription Targets** | 246 (6.3%) | **Upsell Subscription** | Mid-tenure (avg 24.0 purchases) non-subscribed promo buyers. Growing value; lock in before discount removal. | **MEDIUM** | Medium |
| **3. Acquisition Monitor** | 180 (4.6%) | **Monitor & Nurture** | Low-tenure (avg 6.9 purchases) non-subscribed promo buyers. Early lifecycle; do not disrupt onboarding. | **LOW** | Low |
| **4. Active Subscribers** | 1,053 (27.0%) | **Retain & Reward** | Subscribed promo buyers (avg 26.1 purchases). Highly committed; pivot rewards to non-monetary value. | **VERY HIGH** | High |
| **5. Organic Customers** | 2,223 (57.0%) | **Protect Margins** | Full-price buyers (56.1% female, 43.9% male). Buying organically. **Do not introduce promotions.** | **CRITICAL** | Low |

---

## 2. Operational Playbooks

### Playbook 1: Phased Promo Sunset (Segment 1)
* **Target Cohort**: 198 customers (100% male, avg 43.16 purchases, avg spend $58.58).
* **Objective**: Shift Estimated Transaction Value of $11.6K to full price (Estimated Margin Recovery: approximately $2.3K per order cycle, assuming an average 20% discount).
* **Timeline**: 90-day rollout.
* **Operational Steps**:
  * **Days 1–30 (Communication)**: Pivot email outreach away from discount-centric codes toward exclusive content and new arrivals (Clothing and Accessories represent 80.8% of their purchases).
  * **Days 31–60 (Reduction)**: Restrict generic promo code usage. Introduce a discount cap (e.g., maximum $10 off instead of a percentage discount) or increase the minimum spend threshold for this group to $80 (average transaction size is currently $58.58).
  * **Days 61–90 (Sunset)**: Complete removal of discount access. Replace with non-monetary loyalty rewards (e.g., free express shipping or early access to seasonal collections).

### Playbook 2: Subscription Upsell Funnel (Segment 2)
* **Target Cohort**: 246 customers (100% male, avg 24.02 purchases, avg spend $59.26).
* **Objective**: Convert mid-tenure promo buyers to active subscribers to secure volume.
* **Timeline**: 60-day campaign.
* **Operational Tactic**:
  * Leverage their current promotion reliance. Offer a "Subscriber Discount" campaign: *“Subscribe today and lock in a 10% discount on every purchase.”* 
  * Because 100% of subscribers in the dataset utilize discounts, this aligns with existing customer behavior. 
  * **The Loyalty Payoff**: Converting them to subscription raises their Framework B score by **30 points** (e.g., from an average of 24.02 to 54.02), moving many close to the Champion threshold and securing recurring transaction frequency.

### Playbook 3: Margin Protection (Segment 5)
* **Target Cohort**: 2,223 customers (56.1% female, 43.9% male, avg 25.06 purchases, avg spend $60.13).
* **Objective**: Insulate organic full-price buyers from promotional messaging.
* **Operational Rule**:
  * **DO NOT** target this segment with discount codes, seasonal sales, or promotional markdowns. They buy organically at full price and have a highly stable purchase history.
  * Focus engagement on brand affinity, product drops, and customer satisfaction (ensure rating stays above 4.3).

---

## 3. Risk Mitigation & Testing

### 3.1 Churn Prevention (The "Sunset" Risk)
Sunsetting promotions for Segment 1 (High-Tenure) carries a risk of customer attrition if they are transactional discount seekers.
* **Mitigation**: Swap discounts for logistics value. Offer **Free Express Shipping** (our Top ICP behavioral preference) for orders above $50. This costs less than the typical 20% discount but carries high perceived value.
* **A/B Testing Model**:
  * **Test Group A (99 customers)**: Immediate promotion sunset + Free Express Shipping.
  * **Test Group B (99 customers)**: Traditional promotional codes maintained.
  * **Evaluation Period**: 60 days. Monitor transaction volume, average spend, and customer review ratings. Proceed with the sunset if Group A's transaction rate drop is $< 5\%$ compared to Group B.

### 3.2 Gender-Specific Loyalty Track
Because the dataset has a strict synthetic constraint where Females cannot subscribe and receive zero promos, they are structurally disadvantaged under composite scoring models.
* **Action**: Create a distinct marketing cohort for Females. Do not target them with subscription prompts (as the feature is non-functional or unavailable for this group in the source database). Instead, evaluate them on a **Tenure-Only Track** (Framework A) and reward their 100% organic full-price behavior with early access to clothing releases and accessories.

---

## 4. Key Performance Indicators (KPIs) to Track

To evaluate the success of the retention playbook, the executive team must monitor the following metrics on a monthly cadence:

1. **Incremental Margin Recovered ($)**:
   $$\text{Margin Recovered} = \text{Transactions by Segment 1} \times (\text{Average Discount Value Saved})$$
2. **Subscription Conversion Rate (%)**:
   $$\text{Conversion Rate} = \frac{\text{Conversions from Segment 2 to Subscribed}}{\text{Total Segment 2 Customers}} \times 100$$
3. **Sunset Cohort Churn Rate (%)**:
   $$\text{Churn Rate} = \frac{\text{Segment 1 Customers with 0 transactions in 90 days}}{\text{Total Segment 1 Customers}} \times 100$$
4. **Organic Segment Stability (Target KPI - Forward-Looking, Not Historical)**:
   $$\text{Organic Revenue Share} = \frac{\text{Full-Price Segment Revenue}}{\text{Total Revenue}} \times 100$$
   *(Future Operating Target: Maintain at $\ge 55\%$ of total sales).*
