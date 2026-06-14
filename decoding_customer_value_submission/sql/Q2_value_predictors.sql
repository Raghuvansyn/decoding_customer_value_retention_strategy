-- =============================================================================
-- FILE        : sql/Q2_value_predictors.sql
-- PROJECT     : Decoding Customer Value — D2C Fashion Brand
-- BUSINESS Q  : "Who are our most valuable customers, and what demographic
--               and transactional attributes predict high Framework B loyalty?"
-- FRAMEWORK   : Loyalty Framework B (primary)
--
-- STRUCTURE   :
--   CTE 1 — population_totals   : baseline metrics for comparison calculations
--   CTE 2 — demographic_summary : loyalty metrics by age band and gender
--   CTE 3 — cadence_summary     : loyalty metrics across purchase frequencies
--   CTE 4 — product_summary     : loyalty metrics by category and season
--   CTE 5 — transaction_summary : loyalty metrics by payment method
--
-- OUTPUT TABLES :
--   Result Set 1 — Demographic Predictors (Age Band & Gender)
--   Result Set 2 — Purchase Cadence Predictors (Self-Reported Frequency)
--   Result Set 3 — Product & Merchandising Predictors (Category & Season)
--   Result Set 4 — Checkout Channel Predictors (Payment Method)
--
-- EXPECTED KEY FINDING :
--   Demographics and purchase categories exhibit near-uniform distributions due
--   to synthetic data limits, showing little correlation with loyalty scores.
--   However, a severe gender bias exists: 100% of Female customers are marked
--   unsubscribed and full-price (0% promotion rate), while Males show a 39.7%
--   subscription rate and 63.2% promotion rate. This skew must be factored
--   into demographic targeting and dashboard design.
-- =============================================================================


-- =============================================================================
-- CTE 1: Population Totals
-- Baseline metrics for comparison calculations across sub-segments.
-- =============================================================================
WITH population_totals AS (

    SELECT
        COUNT(*)                             AS total_customers,
        AVG(loyalty_score_b)                 AS overall_avg_score_b,
        AVG(previous_purchases)              AS overall_avg_purchases,
        AVG(purchase_amount_usd)             AS overall_avg_spend,
        AVG(CAST(subscription_flag AS FLOAT)) AS overall_subscription_rate,
        AVG(CAST(discount_dependent AS FLOAT)) AS overall_discount_rate,
        AVG(CAST(high_value_confirmed AS FLOAT)) AS overall_confirmed_hv_rate
    FROM v_customer_base

),


-- =============================================================================
-- CTE 2: Demographic Summary
-- Aggregates customer counts and loyalty signals by Age Band and Gender.
-- Exposes the severe synthetic gender skew in subscriptions and discounts.
-- =============================================================================
demographic_summary AS (

    SELECT
        age_band,
        gender,
        COUNT(*)                                                AS customer_count,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,
        ROUND(AVG(CAST(discount_dependent AS FLOAT)) * 100, 1) AS discount_rate_pct,
        ROUND(AVG(CAST(high_value_confirmed AS FLOAT)) * 100, 1) AS confirmed_hv_rate_pct
    FROM v_customer_base
    GROUP BY age_band, gender

),


-- =============================================================================
-- CTE 3: Cadence Summary
-- Aggregates metrics by self-reported Frequency of Purchases to evaluate
-- whether verbal survey responses match transactional reality.
-- =============================================================================
cadence_summary AS (

    SELECT
        frequency_of_purchases,
        frequency_score,
        COUNT(*)                                                AS customer_count,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,
        ROUND(AVG(CAST(discount_dependent AS FLOAT)) * 100, 1) AS discount_rate_pct,
        ROUND(AVG(CAST(high_value_confirmed AS FLOAT)) * 100, 1) AS confirmed_hv_rate_pct
    FROM v_customer_base
    GROUP BY frequency_of_purchases, frequency_score

),


-- =============================================================================
-- CTE 4: Product Summary
-- Aggregates metrics by Product Category and Season to identify potential
-- entry points or seasonal drivers of customer lifetime value.
-- =============================================================================
product_summary AS (

    SELECT
        category,
        season,
        COUNT(*)                                                AS customer_count,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,
        ROUND(AVG(CAST(discount_dependent AS FLOAT)) * 100, 1) AS discount_rate_pct,
        ROUND(AVG(CAST(high_value_confirmed AS FLOAT)) * 100, 1) AS confirmed_hv_rate_pct
    FROM v_customer_base
    GROUP BY category, season

),


-- =============================================================================
-- CTE 5: Transaction Summary
-- Aggregates metrics by Payment Method to detect transactional channel
-- preferences and correlations with customer value.
-- =============================================================================
transaction_summary AS (

    SELECT
        payment_method,
        COUNT(*)                                                AS customer_count,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,
        ROUND(AVG(CAST(discount_dependent AS FLOAT)) * 100, 1) AS discount_rate_pct,
        ROUND(AVG(CAST(high_value_confirmed AS FLOAT)) * 100, 1) AS confirmed_hv_rate_pct
    FROM v_customer_base
    GROUP BY payment_method

)


-- =============================================================================
-- RESULT SET 1: Demographic Predictors (Age Band & Gender)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Average loyalty_score_b is remarkably flat across all demographics (~43.5
--   to ~46.1), proving that age and gender have minimal organic correlation
--   with customer value in this dataset due to uniform synthetic generation.
--   
--   CRITICAL FINDING: There is a severe structural bias in the raw data.
--   100% of Female customers are marked with zero subscriptions and zero
--   promotions/discounts (100% full-price, 0% subscribed). Male customers show
--   a ~39.7% subscription rate and a ~63.2% promotion rate.
--   
--   Under Framework B scoring:
--   - Females receive 0 pts for subscription (30% weight) and the full 20 pts
--     for no-discount (20% weight), locking their maximum score at 70.0.
--   - Males can achieve up to 100.0 by being both subscribed and discount-free.
--   Consequently, the "Champion" segment will naturally underrepresent females
--   (11.3% of Females vs 17.4% of Males) despite Females being our highest-margin
--   customers. targeting and playbook design must account for this bias.
-- =============================================================================

SELECT
    d.age_band,
    d.gender,
    d.customer_count,
    ROUND(d.customer_count * 100.0 / t.total_customers, 1)  AS pct_of_base,
    d.avg_loyalty_score_b,
    ROUND(d.avg_loyalty_score_b - t.overall_avg_score_b, 2) AS score_diff_from_avg,
    d.avg_previous_purchases,
    d.avg_spend_usd,
    d.subscription_rate_pct,
    d.discount_rate_pct,
    d.confirmed_hv_rate_pct

FROM demographic_summary d
CROSS JOIN population_totals t
ORDER BY d.age_band, d.gender;

-- =============================================================================
-- RESULT SET 2: Purchase Cadence Predictors (Self-Reported Frequency)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Self-reported purchase frequency (survey-based) shows no correlation with
--   actual tenure (previous_purchases) or loyalty scores. Average loyalty
--   scores are near-identical across all cadence groups (~44.0 to ~45.8).
--   
--   Customers reporting a "Weekly" cadence have a similar number of previous
--   purchases (~25.4) and average spend (~$60) compared to those reporting an
--   "Annually" cadence. This suggests self-reported survey frequency is highly
--   noisy or aspirational.
--   
--   Strategic recommendation: Do not rely on self-reported frequency bands
--   for CLV forecasting or customer tiered benefits. Always rely on actual
--   transactional history (previous_purchases) as the single source of truth.
-- =============================================================================

;   -- Terminate Result Set 1

SELECT
    c.frequency_of_purchases,
    c.frequency_score,
    c.customer_count,
    ROUND(c.customer_count * 100.0 / t.total_customers, 1)  AS pct_of_base,
    c.avg_loyalty_score_b,
    ROUND(c.avg_loyalty_score_b - t.overall_avg_score_b, 2) AS score_diff_from_avg,
    c.avg_previous_purchases,
    c.avg_spend_usd,
    c.subscription_rate_pct,
    c.discount_rate_pct,
    c.confirmed_hv_rate_pct

FROM cadence_summary c
CROSS JOIN population_totals t
ORDER BY c.frequency_score DESC;

-- =============================================================================
-- RESULT SET 3: Product & Merchandising Predictors (Category & Season)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Average loyalty scores and spending patterns show complete consistency
--   across all product categories and seasons, indicating that no specific
--   product acts as a distinct loyalty "gatekeeper" or retention anchor.
--   
--   Accessories and Footwear have slightly higher average scores (~45.0 and ~45.1),
--   but the variance is too small to justify category-specific loyalty tiers.
--   
--   Strategic recommendation: Maintain consistent cross-category retention
--   incentives. Marketing should treat all product purchases as part of a
--   unified brand experience rather than segmenting by product affinity.
-- =============================================================================

;   -- Terminate Result Set 2

SELECT
    p.category,
    p.season,
    p.customer_count,
    ROUND(p.customer_count * 100.0 / t.total_customers, 1)  AS pct_of_base,
    p.avg_loyalty_score_b,
    p.avg_previous_purchases,
    p.avg_spend_usd,
    p.subscription_rate_pct,
    p.discount_rate_pct,
    p.confirmed_hv_rate_pct

FROM product_summary p
CROSS JOIN population_totals t
ORDER BY p.category,
    CASE p.season
        WHEN 'Spring' THEN 1
        WHEN 'Summer' THEN 2
        WHEN 'Fall'   THEN 3
        WHEN 'Winter' THEN 4
    END;

-- =============================================================================
-- RESULT SET 4: Checkout Channel Predictors (Payment Method)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Checkout channel shows minimal variation, with Debit Card and Credit Card users
--   demonstrating marginally higher average loyalty scores (~45.4 and ~45.2)
--   than Bank Transfer users (~43.7).
--   
--   Because payment method is not a strong predictor of customer value,
--   promotions or tiers based on payment type are unlikely to yield high ROI.
--   
--   Strategic recommendation: Focus checkout optimization efforts on transaction
--   cost reduction (e.g. promoting Venmo or Bank Transfer if payment fees are lower)
--   and friction reduction, rather than treating checkout channels as signals
--   of loyalty.
-- =============================================================================

;   -- Terminate Result Set 3

SELECT
    tr.payment_method,
    tr.customer_count,
    ROUND(tr.customer_count * 100.0 / t.total_customers, 1)  AS pct_of_base,
    tr.avg_loyalty_score_b,
    ROUND(tr.avg_loyalty_score_b - t.overall_avg_score_b, 2) AS score_diff_from_avg,
    tr.avg_previous_purchases,
    tr.avg_spend_usd,
    tr.subscription_rate_pct,
    tr.discount_rate_pct,
    tr.confirmed_hv_rate_pct

FROM transaction_summary tr
CROSS JOIN population_totals t
ORDER BY tr.avg_loyalty_score_b DESC;

-- =============================================================================
-- END OF Q2
-- Next file: sql/Q3_geo_opportunity.sql
-- =============================================================================
