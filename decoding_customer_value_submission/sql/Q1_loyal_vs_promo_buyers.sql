-- =============================================================================
-- FILE        : sql/Q1_loyal_vs_promo_buyers.sql
-- PROJECT     : Decoding Customer Value — D2C Fashion Brand
-- BUSINESS Q  : "Who are the genuinely loyal customers vs. those who only buy
--               when there is a discount?"
-- FRAMEWORK   : Loyalty Framework B (primary) · Framework A (benchmark)
--
-- STRUCTURE   :
--   CTE 1 — population_totals     : dataset-wide denominators for % calculations
--   CTE 2 — promo_segment_profile : per discount-group behavioural summary
--   CTE 3 — tier_x_discount       : Framework B tier crossed with discount status
--   CTE 4 — framework_divergence  : customers where A says High but B disagrees
--
-- OUTPUT TABLES :
--   Result Set 1 — Promo vs. Non-Promo: Head-to-Head Profile
--   Result Set 2 — Value Tier × Discount Status Cross-Tab
--   Result Set 3 — Framework A vs B Divergence (the sunset candidate pool)
--   Result Set 4 — Subscription Conversion Gap
--
-- EXPECTED KEY FINDING :
--   Discount users and non-users have near-identical previous_purchases averages
--   (~25.7 vs ~25.1). This confirms the promo programme is margin cost, not a
--   loyalty-building mechanism. The primary strategic recommendation follows from
--   this finding: selective promo sunset for high-tenure, non-subscribed buyers.
-- =============================================================================


-- =============================================================================
-- CTE 1: Population Totals
-- Dataset-wide denominators used in percentage calculations below.
-- Computed once and referenced in all result sets to avoid redundant subqueries.
-- =============================================================================
WITH population_totals AS (

    SELECT
        COUNT(*)                          AS total_customers,
        SUM(discount_dependent)           AS total_promo_buyers,
        COUNT(*) - SUM(discount_dependent) AS total_fullprice_buyers,
        AVG(previous_purchases)           AS overall_avg_purchases,
        AVG(purchase_amount_usd)          AS overall_avg_spend,
        AVG(loyalty_score_b)              AS overall_avg_score_b,
        AVG(CAST(subscription_flag AS FLOAT)) AS overall_subscription_rate
    FROM v_customer_base

),


-- =============================================================================
-- CTE 2: Promo Segment Profile
-- Computes behavioural and loyalty metrics split by discount status.
-- This is the primary evidence table for the core hypothesis test.
-- =============================================================================
promo_segment_profile AS (

    SELECT
        -- Segment label
        CASE discount_dependent
            WHEN 1 THEN 'Promo Buyer'
            WHEN 0 THEN 'Full-Price Buyer'
        END                                                     AS buyer_type,

        discount_dependent,

        -- Volume
        COUNT(*)                                                AS customer_count,

        -- ── Tenure signal (Framework A proxy) ──────────────────────────────
        ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
        MIN(previous_purchases)                                 AS min_previous_purchases,
        MAX(previous_purchases)                                 AS max_previous_purchases,

        -- ── Spend ────────────────────────────────────────────────────────────
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,

        -- ── Framework B composite loyalty score ──────────────────────────────
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,

        -- ── Voluntary commitment (subscription) ──────────────────────────────
        -- Subscribed customers who also use discounts are commercially conflicted:
        -- they have committed to the brand but still demand promotional pricing.
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,

        -- ── Satisfaction ─────────────────────────────────────────────────────
        ROUND(AVG(review_rating), 2)                            AS avg_review_rating,

        -- Satisfied rate (rating ≥ 4.3)
        ROUND(
            SUM(CASE WHEN satisfaction_flag = 'Satisfied' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*),
        1)                                                      AS satisfied_rate_pct,

        -- At-Risk rate (rating < 3.5) — flight risk within each buyer type
        ROUND(
            SUM(CASE WHEN satisfaction_flag = 'At Risk' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*),
        1)                                                      AS at_risk_rate_pct,

        -- ── Confirmed high-value rate ─────────────────────────────────────────
        -- What share of each buyer type passes the dual-validation loyalty check?
        ROUND(
            AVG(CAST(high_value_confirmed AS FLOAT)) * 100,
        1)                                                      AS confirmed_hv_rate_pct,

        -- ── Purchase frequency ────────────────────────────────────────────────
        ROUND(AVG(frequency_score), 3)                          AS avg_frequency_score

    FROM v_customer_base
    GROUP BY discount_dependent

),


-- =============================================================================
-- CTE 3: Tier × Discount Status Cross-Tab
-- Crosses Framework B value tiers with promo buyer status.
-- Reveals which tiers are promo-saturated (Champion with high discount rate =
-- a commercially dangerous combination — loyal tenure but margin-eroding behaviour).
-- =============================================================================
tier_x_discount AS (

    SELECT
        value_tier,
        value_tier_rank,
        discount_dependent,

        CASE discount_dependent
            WHEN 1 THEN 'Promo Buyer'
            WHEN 0 THEN 'Full-Price Buyer'
        END                                                     AS buyer_type,

        COUNT(*)                                                AS customer_count,
        ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,
        ROUND(AVG(review_rating), 2)                            AS avg_review_rating,

        -- Promo sunset candidates within this tier-discount cell
        SUM(promo_sunset_candidate)                             AS sunset_candidates_in_cell

    FROM v_customer_base
    GROUP BY value_tier, value_tier_rank, discount_dependent

),


-- =============================================================================
-- CTE 4: Framework A vs B Divergence
-- Identifies customers ranked 'High' by Framework A (tenure) but NOT 'Champion'
-- by Framework B (composite). These are high-tenure discount-dependent buyers —
-- the exact population for whom the promo programme is failing the brand.
-- This divergence between the two frameworks is itself a deliverable finding.
-- =============================================================================
framework_divergence AS (

    SELECT
        -- Classification of divergence type
        CASE
            WHEN loyalty_score_a = 'High' AND value_tier = 'Champion'
                THEN 'Consistent: A-High + B-Champion'
            WHEN loyalty_score_a = 'High' AND value_tier != 'Champion'
                THEN 'DIVERGE: A-High but NOT B-Champion'   -- primary finding
            WHEN loyalty_score_a != 'High' AND value_tier = 'Champion'
                THEN 'DIVERGE: B-Champion but NOT A-High'   -- new loyalists via sub + no discount
            ELSE
                'Consistent: Non-high on both'
        END                                                     AS divergence_type,

        COUNT(*)                                                AS customer_count,
        ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(CAST(discount_dependent AS FLOAT)) * 100, 1) AS discount_rate_pct,
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,
        SUM(promo_sunset_candidate)                             AS promo_sunset_candidates

    FROM v_customer_base
    GROUP BY divergence_type

)


-- =============================================================================
-- RESULT SET 1: Promo vs. Non-Promo — Head-to-Head Profile
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   If avg_previous_purchases and avg_loyalty_score_b are near-identical between
--   'Promo Buyer' and 'Full-Price Buyer', the promotional programme is confirmed
--   to NOT be driving loyalty — it is pure margin erosion.
--   Expected result: difference in avg_previous_purchases < 2.0 purchases.
-- =============================================================================

SELECT
    p.buyer_type,
    p.customer_count,
    ROUND(p.customer_count * 100.0 / t.total_customers, 1)  AS pct_of_base,
    p.avg_previous_purchases,
    ROUND(p.avg_previous_purchases - t.overall_avg_purchases, 2) AS diff_from_overall_avg,
    p.avg_spend_usd,
    p.avg_loyalty_score_b,
    p.subscription_rate_pct,
    p.avg_review_rating,
    p.satisfied_rate_pct,
    p.at_risk_rate_pct,
    p.confirmed_hv_rate_pct,
    p.avg_frequency_score

FROM promo_segment_profile p
CROSS JOIN population_totals t
ORDER BY p.discount_dependent DESC;   -- Promo Buyer first for comparison direction

-- =============================================================================
-- RESULT SET 2: Value Tier × Discount Status Cross-Tab
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Champions who are also Promo Buyers have high tenure but are margin-eroding.
--   Their sunset_candidates_in_cell count = the first wave of the rollout plan.
--   Growth + Promo Buyer = conversion opportunity (subscription pitch without
--   discount removal yet). Casual + Promo Buyer = do not invest in retention.
-- =============================================================================

;   -- Terminate Result Set 1

SELECT
    value_tier,
    buyer_type,
    customer_count,
    avg_previous_purchases,
    avg_loyalty_score_b,
    avg_spend_usd,
    subscription_rate_pct,
    avg_review_rating,
    sunset_candidates_in_cell

FROM tier_x_discount
ORDER BY value_tier_rank ASC, discount_dependent DESC;

-- =============================================================================
-- RESULT SET 3: Framework A vs B Divergence
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Rows labelled 'DIVERGE: A-High but NOT B-Champion' are the most important.
--   These customers look loyal by tenure alone (A says High) but their composite
--   score (B) is suppressed by discount dependency and/or no subscription.
--   This group IS the promo_sunset_candidate population.
--   discount_rate_pct will be near 100% for this divergent group — confirming
--   that the tenure is promo-built, not organically earned.
-- =============================================================================

;   -- Terminate Result Set 2

SELECT
    divergence_type,
    customer_count,
    avg_previous_purchases,
    avg_loyalty_score_b,
    discount_rate_pct,
    subscription_rate_pct,
    promo_sunset_candidates

FROM framework_divergence
ORDER BY
    CASE divergence_type
        WHEN 'DIVERGE: A-High but NOT B-Champion' THEN 1    -- most important row first
        WHEN 'Consistent: A-High + B-Champion'    THEN 2
        WHEN 'DIVERGE: B-Champion but NOT A-High' THEN 3
        ELSE 4
    END;

-- =============================================================================
-- RESULT SET 4: Subscription Conversion Gap
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Among Promo Buyers (discount_dependent=1) who are NOT subscribed, what is
--   their average loyalty_score_b and previous_purchases? If these metrics are
--   respectable (e.g., score_b ≥ 40, purchases ≥ 25), they are viable candidates
--   for subscription conversion BEFORE discount removal begins.
--   Converting them to subscribers raises their Framework B score by 30 points,
--   moving many from Growth → Champion tier — reducing the margin risk of the
--   promo sunset without losing the customer relationship.
-- =============================================================================

;   -- Terminate Result Set 3

SELECT
    -- Quadrant label for the conversion strategy
    CASE
        WHEN discount_dependent = 1 AND subscription_flag = 0 THEN 'TARGET: Promo-Only (convert first)'
        WHEN discount_dependent = 1 AND subscription_flag = 1 THEN 'MONITOR: Promo + Subscribed'
        WHEN discount_dependent = 0 AND subscription_flag = 1 THEN 'PROTECT: Full-Price Subscribed (ICP)'
        WHEN discount_dependent = 0 AND subscription_flag = 0 THEN 'NURTURE: Full-Price Non-Subscribed'
    END                                                         AS strategic_quadrant,

    COUNT(*)                                                    AS customer_count,
    ROUND(AVG(previous_purchases), 2)                           AS avg_previous_purchases,
    ROUND(AVG(loyalty_score_b), 2)                              AS avg_loyalty_score_b,
    ROUND(AVG(purchase_amount_usd), 2)                          AS avg_spend_usd,
    ROUND(AVG(review_rating), 2)                                AS avg_review_rating,
    ROUND(AVG(frequency_score), 3)                              AS avg_frequency_score,
    SUM(promo_sunset_candidate)                                 AS promo_sunset_candidates,
    SUM(high_value_confirmed)                                   AS confirmed_high_value

FROM v_customer_base
GROUP BY strategic_quadrant
ORDER BY
    CASE strategic_quadrant
        WHEN 'TARGET: Promo-Only (convert first)'    THEN 1
        WHEN 'MONITOR: Promo + Subscribed'           THEN 2
        WHEN 'NURTURE: Full-Price Non-Subscribed'    THEN 3
        WHEN 'PROTECT: Full-Price Subscribed (ICP)'  THEN 4
    END;

-- =============================================================================
-- END OF Q1
-- Next file: sql/Q2_value_predictors.sql
-- =============================================================================
