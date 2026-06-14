-- =============================================================================
-- FILE        : sql/Q4_promo_restructure.sql
-- PROJECT     : Decoding Customer Value — D2C Fashion Brand
-- BUSINESS Q  : "How can we restructure our promotional program, and who are the
--               primary candidates for discount sunsetting vs. subscription upsells?"
-- FRAMEWORK   : Loyalty Framework B (primary)
--
-- STRUCTURE   :
--   CTE 1 — population_totals   : baseline metrics for national comparison
--   CTE 2 — sunset_candidates   : filtered subset of high-tenure, promo-reliant, non-subscribed buyers
--   CTE 3 — conversion_funnel   : promo-only buyers grouped by tenure bands
--   CTE 4 — playbook_segments   : five mutually exclusive customer groups for targeting
--
-- OUTPUT TABLES :
--   Result Set 1 — Profile of Promo Sunset Candidates (The Target Cohort)
--   Result Set 2 — Promo Dependency by Value Tier (Margin Risk Assessment)
--   Result Set 3 — Demographic, Product, and Geo Breakdown of Sunset Candidates
--   Result Set 4 — Subscription Conversion Opportunity Analysis
--   Result Set 5 — Retention Playbook Target Segments (Ranked by Business Impact)
--
-- EXPECTED KEY FINDING :
--   - 198 customers are identified as promo sunset candidates (all male, average of
--     43.16 purchases, average spend $58.58).
--   - Because they are unsubscribed and promo-dependent, their composite loyalty score
--     is capped at 50, locking them in the Growth tier.
--   - In this dataset, there are zero full-price subscribers, meaning subscription
--     is 100% linked to discount usage. 
--   - Segment 5 (Organic Customers) represents the largest cohort (2,223 customers,
--     56.1% female, 43.9% male) who buy organically at full price. This cohort must
--     be insulated from promotions to protect full margins.
-- =============================================================================


-- =============================================================================
-- CTE 1: Population Totals
-- Baseline metrics for comparison calculations across the customer base.
-- =============================================================================
WITH population_totals AS (

    SELECT
        COUNT(*)                             AS total_customers,
        AVG(loyalty_score_b)                 AS overall_avg_score_b,
        AVG(previous_purchases)              AS overall_avg_purchases,
        AVG(purchase_amount_usd)             AS overall_avg_spend,
        AVG(CAST(subscription_flag AS FLOAT)) AS overall_subscription_rate,
        AVG(CAST(discount_dependent AS FLOAT)) AS overall_discount_rate
    FROM v_customer_base

),


-- =============================================================================
-- CTE 2: Sunset Candidates
-- Isolates the 198 high-tenure, promo-dependent, non-subscribed customers.
-- =============================================================================
sunset_candidates AS (

    SELECT *
    FROM v_customer_base
    WHERE promo_sunset_candidate = 1

),


-- =============================================================================
-- CTE 3: Conversion Funnel
-- Groups promo-dependent, non-subscribed customers by tenure bands to
-- evaluate the size and metrics of the subscription upsell pipeline.
-- =============================================================================
conversion_funnel AS (

    SELECT
        CASE
            WHEN previous_purchases >= 35 THEN 'High Tenure (35-50)'
            WHEN previous_purchases >= 15 THEN 'Mid Tenure (15-34)'
            ELSE 'Low Tenure (1-14)'
        END                                                     AS tenure_band,
        COUNT(*)                                                AS customer_count,
        ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
        ROUND(AVG(review_rating), 2)                            AS avg_review_rating
    FROM v_customer_base
    WHERE discount_dependent = 1 AND subscription_flag = 0
    GROUP BY
        CASE
            WHEN previous_purchases >= 35 THEN 'High Tenure (35-50)'
            WHEN previous_purchases >= 15 THEN 'Mid Tenure (15-34)'
            ELSE 'Low Tenure (1-14)'
        END

),


-- =============================================================================
-- CTE 4: Playbook Segments
-- Builds five mutually exclusive customer groups that cover 100% of the base.
-- Calculates counts, metrics, and demographic rates for each.
-- =============================================================================
playbook_segments AS (

    SELECT
        CASE
            WHEN discount_dependent = 1 AND subscription_flag = 0 AND previous_purchases >= 35
                THEN '1. Phased Sunset Candidates (High-Tenure Promo-Only)'
            WHEN discount_dependent = 1 AND subscription_flag = 0 AND previous_purchases BETWEEN 15 AND 34
                THEN '2. Subscription Targets (Mid-Tenure Promo-Only)'
            WHEN discount_dependent = 1 AND subscription_flag = 0 AND previous_purchases < 15
                THEN '3. Acquisition Monitor (Low-Tenure Promo-Only)'
            WHEN discount_dependent = 1 AND subscription_flag = 1
                THEN '4. Active Subscribers (Promo-Dependent)'
            ELSE '5. Organic Customers (Full-Price Non-Subscribed)'
        END                                                     AS playbook_segment,
        COUNT(*)                                                AS customer_count,
        ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,
        ROUND(AVG(CAST(discount_dependent AS FLOAT)) * 100, 1) AS discount_rate_pct,
        ROUND(SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS female_pct
    FROM v_customer_base
    GROUP BY
        CASE
            WHEN discount_dependent = 1 AND subscription_flag = 0 AND previous_purchases >= 35
                THEN '1. Phased Sunset Candidates (High-Tenure Promo-Only)'
            WHEN discount_dependent = 1 AND subscription_flag = 0 AND previous_purchases BETWEEN 15 AND 34
                THEN '2. Subscription Targets (Mid-Tenure Promo-Only)'
            WHEN discount_dependent = 1 AND subscription_flag = 0 AND previous_purchases < 15
                THEN '3. Acquisition Monitor (Low-Tenure Promo-Only)'
            WHEN discount_dependent = 1 AND subscription_flag = 1
                THEN '4. Active Subscribers (Promo-Dependent)'
            ELSE '5. Organic Customers (Full-Price Non-Subscribed)'
        END

)


-- =============================================================================
-- RESULT SET 1: Profile of Promo Sunset Candidates
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   This query profiles the 198 target customers for promotional sunsetting.
--   
--   MATHEMATICAL FINDING: Because these customers have subscription_flag = 0
--   and discount_dependent = 1, their Framework B score simplifies to:
--   Score_B = (tenure_score * 0.5) * 100 = 50 * (previous_purchases / 50) = previous_purchases.
--   Thus, their composite loyalty score is mathematically identical to their
--   previous purchases.
--   
--   Because their score is capped at 50, all 198 are locked in the 'Growth' tier
--   and none can become 'Champions', despite having high tenure (avg 43.16 purchases).
--   Also, their confirmed high-value rate is 0% because they fail the cadence-score
--   dual validation (requires score >= 65).
--   
--   Sunsetting promotions for this group offers immediate margin recovery on
--   high-volume repeat transactions.
-- =============================================================================

SELECT
    COUNT(*)                                                AS candidate_count,
    ROUND(COUNT(*) * 100.0 / t.total_customers, 1)          AS pct_of_base,
    ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
    ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
    ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
    ROUND(AVG(review_rating), 2)                            AS avg_review_rating,
    ROUND(AVG(CAST(high_value_confirmed AS FLOAT)) * 100, 1) AS confirmed_hv_rate_pct

FROM sunset_candidates
CROSS JOIN population_totals t;

-- =============================================================================
-- RESULT SET 2: Promo Dependency by Value Tier (Margin Risk Assessment)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Examines which value tiers rely on promotions.
--   - 'Casual' customers have a 43.4% promotion rate (avg 10.58 purchases).
--   - 'Growth' customers have a 39.0% promotion rate (avg 27.87 purchases).
--   - 'Champion' customers have the highest promotion rate: 56.6% (avg 44.58 purchases).
--   
--   This high promotion rate in Champions represents a critical risk: more than
--   half of our most valuable customer segment relies on discounts. However,
--   because 100% of subscribers are discount users, these 341 promo-dependent
--   Champions are active subscribers. We must treat them with care (conversion to
--   non-monetary benefits) to avoid driving them to churn.
-- =============================================================================

;   -- Terminate Result Set 1

SELECT
    value_tier,
    COUNT(*)                                                AS customer_count,
    SUM(discount_dependent)                                 AS promo_buyer_count,
    ROUND(AVG(CAST(discount_dependent AS FLOAT)) * 100, 1) AS promo_rate_pct,
    ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
    ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
    ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd

FROM v_customer_base
GROUP BY value_tier, value_tier_rank
ORDER BY value_tier_rank;

-- =============================================================================
-- RESULT SET 3: Demographic, Product, and Geo Breakdown of Sunset Candidates
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Consolidates three dimensions of the 198 sunset candidates to help marketing
--   localize and tailor their messaging.
--   - Demographics: Candidates are evenly distributed across age bands (Adults
--     lead slightly with 56 candidates, Seniors are lowest with 43).
--   - Category: Accessories (85) and Clothing (75) are the dominant product classes,
--     meaning sunsetting campaigns should focus on apparel and accessories.
--   - Geography: 'Underdeveloped' states contain the highest count (91), while
--     'Organic Pull' states contain the fewest (46).
-- =============================================================================

;   -- Terminate Result Set 2

SELECT 
    'Age Band'                                              AS dimension, 
    age_band                                                AS attribute, 
    COUNT(*)                                                AS customer_count, 
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sunset_candidates), 1) AS pct_of_candidates 
FROM sunset_candidates 
GROUP BY age_band

UNION ALL

SELECT 
    'Category'                                              AS dimension, 
    category                                                AS attribute, 
    COUNT(*)                                                AS customer_count, 
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sunset_candidates), 1) AS pct_of_candidates 
FROM sunset_candidates 
GROUP BY category

UNION ALL

SELECT 
    'Geography Type'                                        AS dimension, 
    geo_demand_type                                         AS attribute, 
    COUNT(*)                                                AS customer_count, 
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sunset_candidates), 1) AS pct_of_candidates 
FROM sunset_candidates 
GROUP BY geo_demand_type;

-- =============================================================================
-- RESULT SET 4: Subscription Conversion Opportunity Analysis
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Analyzes the 624 promo-dependent, non-subscribed customers (all Male).
--   - Low Tenure (180 customers) represent new acquisition. Monitor before action.
--   - Mid Tenure (246 customers) are growing in value. Prioritize for subscription upsells.
--   - High Tenure (198 customers) are the sunset candidates.
--   
--   Converting a customer to subscription increases their Framework B score by
--   30 points. If we convert a sunset candidate (High Tenure, avg score 43.16)
--   to subscription, their score jumps to 73.16, moving them from Growth to
--   Champion. This offsets the margin hit of removing discounts by locking them
--   into recurring brand commitment.
-- =============================================================================

;   -- Terminate Result Set 3

SELECT
    tenure_band,
    customer_count,
    avg_previous_purchases,
    avg_loyalty_score_b,
    avg_spend_usd,
    avg_review_rating

FROM conversion_funnel
ORDER BY
    CASE tenure_band
        WHEN 'High Tenure (35-50)' THEN 1
        WHEN 'Mid Tenure (15-34)'  THEN 2
        WHEN 'Low Tenure (1-14)'   THEN 3
    END;

-- =============================================================================
-- RESULT SET 5: Retention Playbook Target Segments (Ranked by Business Impact)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Exhaustively maps all 3,900 customers into 5 strategic playbook segments
--   and ranks them by potential business impact.
--   
--   1. Phased Sunset Candidates (198): High tenure, promo-only. Phased discount removal.
--      Impact: HIGH (Direct margin recovery on high-frequency transactions).
--   2. Subscription Targets (246): Mid tenure, promo-only. Pitch subscription first.
--      Impact: MEDIUM (Secure customer volume via subscription before sunsetting promos).
--   3. Acquisition Monitor (180): Low tenure, promo-only. Monitor for repeat orders.
--      Impact: LOW (Ensure positive onboarding before promo adjustment).
--   4. Active Subscribers (1,053): Subscribed promo buyers. Protect this cohort.
--      Impact: VERY HIGH (Subscribers drive massive repeat volume. Pivot to early access).
--   5. Organic Customers (2,223): Full-price buyers (56.1% female, 43.9% male).
--      Impact: CRITICAL (Do not offer promos to this group; they buy organically).
-- =============================================================================

;   -- Terminate Result Set 4

SELECT
    p.playbook_segment,
    p.customer_count,
    ROUND(p.customer_count * 100.0 / t.total_customers, 1)  AS pct_of_base,
    p.avg_previous_purchases,
    p.avg_loyalty_score_b,
    p.avg_spend_usd,
    p.female_pct,
    
    CASE 
        WHEN p.playbook_segment LIKE '1.%' THEN 'PHASED PROMO SUNSET'
        WHEN p.playbook_segment LIKE '2.%' THEN 'UPSELL SUBSCRIPTION'
        WHEN p.playbook_segment LIKE '3.%' THEN 'MONITOR & NURTURE'
        WHEN p.playbook_segment LIKE '4.%' THEN 'RETAIN & REWARD'
        WHEN p.playbook_segment LIKE '5.%' THEN 'PROTECT MARGINS (NO PROMOS)'
    END                                                     AS strategic_action,

    CASE 
        WHEN p.playbook_segment LIKE '1.%' THEN 'HIGH'
        WHEN p.playbook_segment LIKE '2.%' THEN 'MEDIUM'
        WHEN p.playbook_segment LIKE '3.%' THEN 'LOW'
        WHEN p.playbook_segment LIKE '4.%' THEN 'VERY HIGH'
        WHEN p.playbook_segment LIKE '5.%' THEN 'CRITICAL'
    END                                                     AS business_impact_rating

FROM playbook_segments p
CROSS JOIN population_totals t
ORDER BY 
    CASE 
        WHEN p.playbook_segment LIKE '5.%' THEN 1 -- Critical first
        WHEN p.playbook_segment LIKE '4.%' THEN 2 -- Very High second
        WHEN p.playbook_segment LIKE '1.%' THEN 3 -- High third
        WHEN p.playbook_segment LIKE '2.%' THEN 4
        WHEN p.playbook_segment LIKE '3.%' THEN 5
    END;

-- =============================================================================
-- END OF Q4
-- Next file: sql/Q5_ideal_customer_profile.sql
-- =============================================================================
