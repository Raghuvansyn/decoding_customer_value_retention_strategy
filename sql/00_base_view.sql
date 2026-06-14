-- =============================================================================
-- FILE        : sql/00_base_view.sql
-- PROJECT     : Decoding Customer Value — D2C Fashion Brand
-- PURPOSE     : Reusable foundation view for all downstream queries (Q1–Q5).
--               All business queries reference v_customer_base, never the raw
--               table directly. This isolates schema changes to one location.
--
-- SOURCE TABLE: customer_features
--               (loaded from data/features.csv produced by the Python pipeline)
--
-- CONVENTIONS :
--   - All engineered columns are already present in the source table.
--   - This view adds no new logic — it selects, aliases, and documents columns.
--   - One utility CASE column (value_tier_rank) is added here to enable
--     ORDER BY tier severity without hardcoding strings in every query.
-- =============================================================================


CREATE VIEW v_customer_base AS

SELECT

    -- ─────────────────────────────────────────────────────────────────────────
    -- IDENTIFIERS
    -- ─────────────────────────────────────────────────────────────────────────
    customer_id,

    -- ─────────────────────────────────────────────────────────────────────────
    -- DEMOGRAPHICS
    -- ─────────────────────────────────────────────────────────────────────────
    age,
    age_band,           -- 'Young Adult (18–29)' | 'Adult (30–44)' | 'Mid-Senior (45–59)' | 'Senior (60–70)'
    gender,             -- 'Male' (68%) | 'Female' (32%) — imbalanced; control for in comparisons
    location,           -- US state (all 50 represented; near-uniform — likely synthetic)
    size,               -- 'S' | 'M' | 'L' | 'XL'

    -- ─────────────────────────────────────────────────────────────────────────
    -- PURCHASE BEHAVIOUR (raw columns)
    -- ─────────────────────────────────────────────────────────────────────────
    category,               -- 'Clothing' | 'Footwear' | 'Outerwear' | 'Accessories'
    item_purchased,
    purchase_amount_usd,    -- range $20–$100; hard ceiling; not alone sufficient for value segmentation
    season,                 -- season of the transaction
    previous_purchases,     -- integer 1–50; the closest proxy to customer tenure in this dataset
    frequency_of_purchases, -- self-reported cadence; cross-validate against previous_purchases
    shipping_type,
    payment_method,
    review_rating,          -- 2.5–5.0; 37 values imputed with category-level median in Python
    subscription_status,    -- 'Yes' | 'No'; raw source for subscription_flag
    discount_applied,       -- 'Yes' | 'No'; raw source for discount_dependent

    -- ─────────────────────────────────────────────────────────────────────────
    -- ENGINEERED FEATURES — FOUNDATION SIGNALS
    -- (computed in notebooks/feature_engineering.ipynb)
    -- ─────────────────────────────────────────────────────────────────────────
    tenure_score,           -- previous_purchases / 50; normalised 0–1
    discount_dependent,     -- 1 = bought under discount; 0 = full-price buyer
    subscription_flag,      -- 1 = subscribed; 0 = not subscribed
    no_discount_flag,       -- inverse of discount_dependent; 1 = full-price
    frequency_score,        -- numeric cadence: Weekly=4.0, Monthly=1.0, Annually=0.08 etc.

    -- ─────────────────────────────────────────────────────────────────────────
    -- ENGINEERED FEATURES — LOYALTY FRAMEWORKS
    -- ─────────────────────────────────────────────────────────────────────────

    -- Framework A: tenure-only percentile rank
    -- 'High' (top 25%) | 'Medium' (middle 50%) | 'Low' (bottom 25%)
    -- Single-variable baseline. Use as benchmark, not primary definition.
    loyalty_score_a,

    -- Framework B: multi-signal composite (PRIMARY)
    -- Score = (tenure_score × 0.50) + (subscription_flag × 0.30) + (no_discount_flag × 0.20) × 100
    -- Range: 0–100. 50/30/20 active design choice (9.1% shift for tenure-heavy, 14.6% shift for sub-heavy).
    loyalty_score_b,

    -- ─────────────────────────────────────────────────────────────────────────
    -- ENGINEERED FEATURES — SEGMENT LABELS
    -- ─────────────────────────────────────────────────────────────────────────

    -- Derived from loyalty_score_b thresholds
    -- 'Champion' (≥65) | 'Growth' (35–64) | 'Casual' (<35)
    value_tier,

    -- Numeric rank for ORDER BY — avoids repeated CASE blocks in every query
    CASE value_tier
        WHEN 'Champion' THEN 1
        WHEN 'Growth'   THEN 2
        WHEN 'Casual'   THEN 3
    END AS value_tier_rank,

    -- 'Satisfied' (≥4.3) | 'Neutral' (3.5–4.2) | 'At Risk' (<3.5)
    satisfaction_flag,

    -- ─────────────────────────────────────────────────────────────────────────
    -- ENGINEERED FEATURES — ACTION FLAGS
    -- ─────────────────────────────────────────────────────────────────────────

    -- 1 = loyalty_score_b ≥ 65 AND frequency_score ≥ 1.0 (monthly or faster)
    -- Dual-validation: both composite score and self-reported cadence must agree
    high_value_confirmed,

    -- 1 = discount_dependent=1 AND subscription_flag=0 AND previous_purchases ≥ 35
    -- Primary target for promotional sunset rollout (Phase 1 of retention playbook)
    promo_sunset_candidate,

    -- ─────────────────────────────────────────────────────────────────────────
    -- ENGINEERED FEATURES — GEOGRAPHIC CLASSIFICATION
    -- ─────────────────────────────────────────────────────────────────────────
    geo_demand_type,        -- 'Organic Pull' | 'Discount Pull' | 'Underdeveloped'
    state_customer_count,   -- number of customers in this state
    state_discount_rate     -- share of customers in this state who received a discount

FROM customer_features;


-- =============================================================================
-- QUICK VALIDATION — run after CREATE VIEW to confirm shape and key invariants
-- =============================================================================

-- Total row count (expect 3,900)
-- SELECT COUNT(*) AS total_customers FROM v_customer_base;

-- Value tier distribution
-- SELECT value_tier, COUNT(*) AS n, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
-- FROM v_customer_base
-- GROUP BY value_tier
-- ORDER BY value_tier_rank;

-- Confirm no nulls in action flags (all must be 0 or 1)
-- SELECT
--     SUM(CASE WHEN discount_dependent     IS NULL THEN 1 ELSE 0 END) AS null_discount_dependent,
--     SUM(CASE WHEN subscription_flag      IS NULL THEN 1 ELSE 0 END) AS null_subscription_flag,
--     SUM(CASE WHEN high_value_confirmed   IS NULL THEN 1 ELSE 0 END) AS null_high_value_confirmed,
--     SUM(CASE WHEN promo_sunset_candidate IS NULL THEN 1 ELSE 0 END) AS null_promo_sunset_candidate
-- FROM v_customer_base;
