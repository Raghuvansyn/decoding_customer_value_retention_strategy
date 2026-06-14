-- =============================================================================
-- FILE        : sql/Q3_geo_opportunity.sql
-- PROJECT     : Decoding Customer Value — D2C Fashion Brand
-- BUSINESS Q  : "Where are our geographic opportunities, and how does customer
--               loyalty and discount dependency vary by state and region?"
-- FRAMEWORK   : Loyalty Framework B (primary)
--
-- STRUCTURE   :
--   CTE 1 — population_totals   : baseline metrics for national comparison
--   CTE 2 — state_level_metrics : aggregated customer value signals per US state
--   CTE 3 — geo_type_summary    : performance metrics aggregated by demand type
--
-- OUTPUT TABLES :
--   Result Set 1 — State-Level Performance Summary (Full Rank)
--   Result Set 2 — Demand Type Comparison (Organic vs. Discount vs. Underdeveloped)
--   Result Set 3 — Top Opportunity States (High Loyalty, Low Promo reliance)
--   Result Set 4 — Strategic Geographic Recommendations Table
--
-- EXPECTED KEY FINDING :
--   - 11 states are classified as 'Organic Pull' (high volume, low promos).
--     These represent the healthiest customer cohorts and primary expansion opportunities.
--   - 13 states are 'Discount Pull' (high volume, high promos), showing margin
--     erosion risk. These are the main targets for the promotional sunset.
--   - 26 states are 'Underdeveloped' (low volume), representing untapped market share
--     where marketing should focus on baseline customer acquisition.
-- =============================================================================


-- =============================================================================
-- CTE 1: Population Totals
-- Baseline metrics for comparison calculations across states and regions.
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
-- CTE 2: State-Level Metrics
-- Aggregates customer value signals per state. Uses the pre-engineered
-- state_customer_count and state_discount_rate fields from the view.
-- =============================================================================
state_level_metrics AS (

    SELECT
        location                                                AS state,
        geo_demand_type,
        -- Reference the pre-engineered state-level features directly
        MAX(state_customer_count)                               AS state_customer_count,
        MAX(state_discount_rate)                                AS state_discount_rate,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,
        ROUND(AVG(CAST(high_value_confirmed AS FLOAT)) * 100, 1) AS confirmed_hv_rate_pct
    FROM v_customer_base
    GROUP BY location, geo_demand_type

),


-- =============================================================================
-- CTE 3: Geo Type Summary
-- Aggregates performance metrics and value tier distributions by demand type.
-- Includes a cross-tab count of the value_tier classifications.
-- =============================================================================
geo_type_summary AS (

    SELECT
        geo_demand_type,
        COUNT(DISTINCT location)                                AS state_count,
        COUNT(*)                                                AS customer_count,
        ROUND(AVG(loyalty_score_b), 2)                          AS avg_loyalty_score_b,
        ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
        ROUND(AVG(CAST(discount_dependent AS FLOAT)) * 100, 1) AS avg_discount_rate_pct,
        ROUND(AVG(CAST(subscription_flag AS FLOAT)) * 100, 1)  AS avg_subscription_rate_pct,
        
        -- Value Tier Distribution
        SUM(CASE WHEN value_tier = 'Champion' THEN 1 ELSE 0 END) AS champion_count,
        SUM(CASE WHEN value_tier = 'Growth'   THEN 1 ELSE 0 END) AS growth_count,
        SUM(CASE WHEN value_tier = 'Casual'   THEN 1 ELSE 0 END) AS casual_count
    FROM v_customer_base
    GROUP BY geo_demand_type

)


-- =============================================================================
-- RESULT SET 1: State-Level Performance Summary (Full Rank)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   This ranking provides a granular look at every state's customer count,
--   spend, and overall loyalty score. We sort by customer volume and then
--   loyalty score.
--   
--   This helps regional teams identify high-performing states and benchmark
--   local discount rates. California, Montana, and Illinois lead in volume
--   for the Organic Pull category, while Missouri and Minnesota lead volume
--   for Discount Pull.
-- =============================================================================

SELECT
    s.state,
    s.geo_demand_type,
    s.state_customer_count                                  AS customer_count,
    ROUND(s.state_customer_count * 100.0 / t.total_customers, 2) AS pct_of_base,
    s.avg_loyalty_score_b,
    s.avg_spend_usd,
    ROUND(s.state_discount_rate * 100.0, 1)                 AS discount_rate_pct,
    s.subscription_rate_pct,
    s.confirmed_hv_rate_pct

FROM state_level_metrics s
CROSS JOIN population_totals t
ORDER BY s.state_customer_count DESC, s.avg_loyalty_score_b DESC;

-- =============================================================================
-- RESULT SET 2: Demand Type Comparison (Organic vs. Discount vs. Underdeveloped)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Comparing the three geo demand types reveals that while average spend and
--   loyalty scores remain consistent across categories due to synthetic uniformity,
--   the volume and promotional characteristics differ significantly.
--   
--   - 'Discount Pull' states (13 states, 1,068 customers) represent the highest
--     loyalty score (45.25) but are heavily reliant on promotions (46.8% discount rate).
--     They also have the highest subscription rate (29.5%).
--   - 'Organic Pull' states (11 states, 965 customers) show strong loyalty (44.65)
--     with a much healthier discount rate (40.0%).
--   - 'Underdeveloped' states represent half the country (26 states) and almost
--     half of the customer base (1,867 customers). This highlights a major brand
--     penetration opportunity; these states represent highly fragmented, low-volume
--     regions where baseline acquisition is the primary goal.
-- =============================================================================

;   -- Terminate Result Set 1

SELECT
    g.geo_demand_type,
    g.state_count,
    g.customer_count,
    ROUND(g.customer_count * 100.0 / t.total_customers, 1)  AS pct_of_base,
    g.avg_loyalty_score_b,
    g.avg_spend_usd,
    g.avg_discount_rate_pct,
    g.avg_subscription_rate_pct,
    
    -- Tier breakdown percentages
    ROUND(g.champion_count * 100.0 / g.customer_count, 1)   AS champion_pct,
    ROUND(g.growth_count * 100.0 / g.customer_count, 1)     AS growth_pct,
    ROUND(g.casual_count * 100.0 / g.customer_count, 1)     AS casual_pct

FROM geo_type_summary g
CROSS JOIN population_totals t
ORDER BY g.customer_count DESC;

-- =============================================================================
-- RESULT SET 3: Top Opportunity States (High Loyalty, Low Promo reliance)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   These states represent the healthiest markets in the country: they have
--   above-average customer counts (>= 78) and below-average discount reliance (< 43%).
--   
--   Alabama, Illinois, and Georgia lead the list with the highest loyalty scores
--   and healthy organic pull. Montana features the lowest discount rate among 
--   large volume states (37.5%). Connecticut stands out as the ultimate organic market,
--   with only a 33.3% discount rate, although it sits right at the volume threshold (78).
--   
--   These states are the primary targets for scaling brand investments, loyalty
--   rewards, and subscription upsell programs because they buy organically.
-- =============================================================================

;   -- Terminate Result Set 2

SELECT
    s.state,
    s.geo_demand_type,
    s.state_customer_count                                  AS customer_count,
    s.avg_loyalty_score_b,
    s.avg_spend_usd,
    ROUND(s.state_discount_rate * 100.0, 1)                 AS discount_rate_pct,
    s.subscription_rate_pct,
    s.confirmed_hv_rate_pct

FROM state_level_metrics s
CROSS JOIN population_totals t
WHERE s.state_customer_count >= 78                          -- Above-average customer volume
  AND s.state_discount_rate < 0.4300                        -- Below-average discount dependency
ORDER BY s.avg_loyalty_score_b DESC, s.state_discount_rate ASC;

-- =============================================================================
-- RESULT SET 4: Strategic Geographic Recommendations Table
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Translates the geographic findings into high-level marketing playbooks.
--   Each demand type is mapped to a distinct commercial action and rationale,
--   providing an actionable roadmap for regional managers.
-- =============================================================================

;   -- Terminate Result Set 3

SELECT
    g.geo_demand_type,
    g.state_count,
    g.customer_count,
    g.avg_loyalty_score_b,
    g.avg_discount_rate_pct,
    
    CASE g.geo_demand_type
        WHEN 'Organic Pull'    THEN 'SCALE & EXPAND'
        WHEN 'Discount Pull'   THEN 'SUNSET PROMOTIONS'
        WHEN 'Underdeveloped'  THEN 'ACQUIRE & SEED'
    END                                                     AS strategic_action,
    
    CASE g.geo_demand_type
        WHEN 'Organic Pull'    THEN 'High-volume states with low discount dependency. These are our healthiest cohorts. Prioritize subscription upsells and premium merchandising to capture maximum lifetime value without margin erosion.'
        WHEN 'Discount Pull'   THEN 'High-volume states heavily reliant on discounts. Pivot customers away from promos through a phased sunsetting campaign. Introduce non-monetary loyalty rewards (e.g., early access) to retain tenure.'
        WHEN 'Underdeveloped'  THEN 'Low customer penetration regardless of discount rates. Focus marketing resources on local brand awareness and acquisition campaigns to build a healthy, full-price customer baseline.'
    END                                                     AS business_rationale

FROM geo_type_summary g
ORDER BY
    CASE g.geo_demand_type
        WHEN 'Organic Pull'    THEN 1
        WHEN 'Discount Pull'   THEN 2
        WHEN 'Underdeveloped'  THEN 3
    END;

-- =============================================================================
-- END OF Q3
-- Next file: sql/Q4_promo_restructure.sql
-- =============================================================================
