-- =============================================================================
-- FILE        : sql/Q5_ideal_customer_profile.sql
-- PROJECT     : Decoding Customer Value — D2C Fashion Brand
-- BUSINESS Q  : "Who is our Ideal Customer Profile (ICP) based on Framework B
--               champions who pass the high-value frequency confirmation?"
-- FRAMEWORK   : Loyalty Framework B (primary)
--
-- STRUCTURE   :
--   CTE 1 — population_totals : baseline metrics for national comparison
--   CTE 2 — icp_base          : filters for value_tier = 'Champion' AND high_value_confirmed = 1
--   CTE 3 to 10 — modal CTEs  : computes top attributes (modes) for the summary table
--
-- OUTPUT TABLES :
--   Result Set 1 — Champion Population Overview (ICP vs. General Base)
--   Result Set 2 — Demographic Profile (Age Band, Gender, Location)
--   Result Set 3 — Behavioral Profile (Category, Season, Frequency, Shipping)
--   Result Set 4 — Payment and Subscription Profile
--   Result Set 5 — Final Ideal Customer Profile Summary Table (Modal Analysis)
--
-- EXPECTED KEY FINDING :
--   - The ICP population consists of 334 customers (8.6% of the customer base).
--   - Due to high_value_confirmed = 1, they are strictly monthly or faster buyers.
--   - The average tenure is 44.54 purchases, and average spend is $60.45.
--   - Gender skew is severe: 78.1% Male vs. 21.9% Female, because Females are
--     synthetically blocked from subscriptions, making it much harder to reach Champion status.
--   - Mid-Seniors (45-59) represent the largest age band (30.8%).
--   - Clothing is the primary category (42.2%), Fall/Summer are top seasons,
--     PayPal is the top payment channel, and Express options dominate shipping.
-- =============================================================================


-- =============================================================================
-- CTE 1: Population Totals
-- National baseline metrics for comparative calculations.
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
-- CTE 2: ICP Base
-- Isolates the 334 premium customers (Value Tier = Champion & Confirmed High Value).
-- =============================================================================
icp_base AS (

    SELECT *
    FROM v_customer_base
    WHERE value_tier = 'Champion' AND high_value_confirmed = 1

),


-- =============================================================================
-- CTEs 3 to 10: Modal Attribute Calculators
-- Identifies the most common (modal) attribute values within the ICP cohort.
-- Uses ROW_NUMBER() window functions to extract the top-ranked rows.
-- =============================================================================
gender_mode AS (
    SELECT gender AS val, COUNT(*) AS cnt, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn FROM icp_base GROUP BY gender
),

age_band_mode AS (
    SELECT age_band AS val, COUNT(*) AS cnt, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn FROM icp_base GROUP BY age_band
),

category_mode AS (
    SELECT category AS val, COUNT(*) AS cnt, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn FROM icp_base GROUP BY category
),

season_mode AS (
    SELECT season AS val, COUNT(*) AS cnt, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn FROM icp_base GROUP BY season
),

payment_mode AS (
    SELECT payment_method AS val, COUNT(*) AS cnt, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn FROM icp_base GROUP BY payment_method
),

shipping_mode AS (
    SELECT shipping_type AS val, COUNT(*) AS cnt, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn FROM icp_base GROUP BY shipping_type
),

location_mode AS (
    SELECT location AS val, COUNT(*) AS cnt, ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn FROM icp_base GROUP BY location
)


-- =============================================================================
-- RESULT SET 1: Champion Population Overview (ICP vs. General Base)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   The ICP population comprises 334 customers, representing 8.6% of our total
--   customer base.
--   
--   This premium cohort represents our absolute best segment:
--   - Average tenure is 44.54 purchases, compared to the national average of 25.35.
--   - Average transaction size ($60.45) is consistent with the base average ($60.15),
--     indicating that loyalty is driven by purchase cadence and volume rather than
--     buying higher-priced items.
--   - Subscription rate is 57.8%, meaning more than half have committed to the brand.
--   - Promotion rate is also 57.8%, aligning with the synthetic constraint that
--     all subscribers are promo users.
-- =============================================================================

SELECT
    (SELECT COUNT(*) FROM icp_base)                         AS icp_customer_count,
    ROUND((SELECT COUNT(*) FROM icp_base) * 100.0 / t.total_customers, 2) AS pct_of_total_base,
    ROUND(AVG(i.previous_purchases), 2)                     AS avg_previous_purchases,
    ROUND(AVG(i.purchase_amount_usd), 2)                      AS avg_spend_usd,
    ROUND(AVG(CAST(i.subscription_flag AS FLOAT)) * 100, 1)  AS subscription_rate_pct,
    ROUND(AVG(CAST(i.discount_dependent AS FLOAT)) * 100, 1) AS discount_rate_pct,
    ROUND(AVG(i.review_rating), 2)                            AS avg_review_rating

FROM icp_base i
CROSS JOIN population_totals t;

-- =============================================================================
-- RESULT SET 2: Demographic Profile (Age Band, Gender, Location)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Demographic analysis of the ICP reveals strong skews:
--   - Gender: 78.1% Male (261) vs 21.9% Female (73). This severe distortion is
--     due to the synthetic data limitation where Females cannot subscribe. Females
--     can only become Champions by having extremely high tenure (purchases >= 45),
--     underrepresenting their margin value (100% full-price).
--   - Age Band: Mid-Seniors (45-59) show the highest density (30.8%), followed closely
--     by Adults (30-44) at 26.9%.
--   - Top Locations: Maryland leads with 15 customers, followed by Arizona (13) and
--     Tennessee (12). High-value confirmed customers are relatively spread out.
-- =============================================================================

;   -- Terminate Result Set 1

SELECT
    age_band,
    gender,
    COUNT(*)                                                AS icp_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS pct_of_icp,
    ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases,
    ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd
FROM icp_base
GROUP BY age_band, gender
ORDER BY age_band, gender;

-- State-level distribution (Top 10 States for ICP targeting)
;

SELECT
    location                                                AS state,
    geo_demand_type,
    COUNT(*)                                                AS icp_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS pct_of_icp,
    ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases
FROM icp_base
GROUP BY location, geo_demand_type
ORDER BY icp_count DESC, avg_previous_purchases DESC
LIMIT 10;

-- =============================================================================
-- RESULT SET 3: Behavioral Profile (Category, Season, Frequency, Shipping)
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Behavioral analysis reveals core product and purchasing patterns:
--   - Category: Clothing is the dominant category for the ICP (42.2%), followed by
--     Accessories (30.8%). These are the key product classes to anchor loyalty campaigns.
--   - Seasonality: FALL and SUMMER lead slightly (26.3% and 26.0%), though seasonal
--     distribution is relatively balanced.
--   - Cadence: Bi-Weekly (26.9%) and Weekly (26.3%) are the top cadences. Low frequency
--     is 0% because high_value_confirmed drops all cadences slower than monthly.
--   - Shipping: Express options dominate (Express 19.2%, Next Day Air 17.7%), suggesting
--     our premium customers value speed and convenience.
-- =============================================================================

;   -- Terminate Result Set 2 (state sub-query)

SELECT
    category,
    season,
    COUNT(*)                                                AS icp_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS pct_of_icp,
    ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd
FROM icp_base
GROUP BY category, season
ORDER BY category,
    CASE season
        WHEN 'Spring' THEN 1
        WHEN 'Summer' THEN 2
        WHEN 'Fall'   THEN 3
        WHEN 'Winter' THEN 4
    END;

-- Cadence & Shipping Preference Table
;

SELECT
    frequency_of_purchases                                  AS purchase_frequency,
    shipping_type,
    COUNT(*)                                                AS icp_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS pct_of_icp
FROM icp_base
GROUP BY frequency_of_purchases, shipping_type
ORDER BY
    CASE frequency_of_purchases
        WHEN 'Weekly'      THEN 1
        WHEN 'Bi-Weekly'   THEN 2
        WHEN 'Fortnightly' THEN 3
        WHEN 'Monthly'     THEN 4
    END,
    icp_count DESC;

-- =============================================================================
-- RESULT SET 4: Payment and Subscription Profile
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   Checkout channel and subscription characteristics of the ICP:
--   - 57.8% of the ICP are active subscribers (who also use discounts).
--   - 42.2% are non-subscribers (who pay full price).
--   - Digital payment methods are highly utilized: PayPal leads with 20.4%,
--     followed by Credit Card at 18.0% and Debit Card at 16.8%.
--   
--   Upselling the remaining 42.2% of non-subscribed Champions (who already buy at
--   full price and have tenure >= 45) to a subscription program is a major priority.
--   This will solidify their long-term commitment and raise recurring margin stability.
-- =============================================================================

;   -- Terminate Result Set 3 (logistics sub-query)

SELECT
    payment_method,
    CASE subscription_flag
        WHEN 1 THEN 'Active Subscriber'
        WHEN 0 THEN 'Non-Subscriber'
    END                                                     AS subscription_status,
    COUNT(*)                                                AS icp_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS pct_of_icp,
    ROUND(AVG(purchase_amount_usd), 2)                      AS avg_spend_usd,
    ROUND(AVG(previous_purchases), 2)                       AS avg_previous_purchases
FROM icp_base
GROUP BY payment_method, subscription_flag
ORDER BY subscription_flag DESC, icp_count DESC;

-- =============================================================================
-- RESULT SET 5: Final Ideal Customer Profile Summary Table
-- ─────────────────────────────────────────────────────────────────────────────
-- BUSINESS INTERPRETATION:
--   This executive-level table aggregates the modal values and averages to build
--   the final target profile for marketing.
--   
--   The Ideal Customer is a Mid-Senior Male buying Clothing in the Fall/Summer,
--   using PayPal, and preferring Express delivery. They have purchased ~45 times
--   historically and transacted monthly or faster.
-- =============================================================================

;   -- Terminate Result Set 4

SELECT 
    'Cohort Size'                                           AS attribute, 
    CAST((SELECT COUNT(*) FROM icp_base) AS VARCHAR)        AS value, 
    '8.6% of total customer database. A tight, highly validated ICP target.' AS business_relevance 

UNION ALL

SELECT 
    'Average Tenure'                                        AS attribute, 
    CAST(ROUND(AVG(previous_purchases), 1) AS VARCHAR) || ' Purchases' AS value, 
    'Highest tenure cohort in base; repeat purchase habits are deeply established.' AS business_relevance 
FROM icp_base

UNION ALL

SELECT 
    'Average Spend'                                         AS attribute, 
    '$' || CAST(ROUND(AVG(purchase_amount_usd), 2) AS VARCHAR) AS value, 
    'Transaction size matches base average. CLV is driven by transaction frequency, not high ticket size.' AS business_relevance 
FROM icp_base

UNION ALL

SELECT 
    'Gender Dominance'                                      AS attribute, 
    val || ' (' || CAST(ROUND(cnt * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS VARCHAR) || '%)' AS value, 
    'Male dominant due to synthetic data bias. Females are locked out of subscription benefits.' AS business_relevance 
FROM gender_mode WHERE rn = 1

UNION ALL

SELECT 
    'Age Cohort Mode'                                       AS attribute, 
    val || ' (' || CAST(ROUND(cnt * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS VARCHAR) || '%)' AS value, 
    'Mid-Senior age band shows highest loyalty density, followed by Adults (30-44).' AS business_relevance 
FROM age_band_mode WHERE rn = 1

UNION ALL

SELECT 
    'Product Category Mode'                                 AS attribute, 
    val || ' (' || CAST(ROUND(cnt * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS VARCHAR) || '%)' AS value, 
    'Clothing is the primary acquisition and retention category for our best customers.' AS business_relevance 
FROM category_mode WHERE rn = 1

UNION ALL

SELECT 
    'Seasonality Mode'                                      AS attribute, 
    val || ' (' || CAST(ROUND(cnt * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS VARCHAR) || '%)' AS value, 
    'Fall is the leading purchase season, though sales remain stable year-round.' AS business_relevance 
FROM season_mode WHERE rn = 1

UNION ALL

SELECT 
    'Payment Method Mode'                                   AS attribute, 
    val || ' (' || CAST(ROUND(cnt * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS VARCHAR) || '%)' AS value, 
    'PayPal leads checkout channel, followed by Credit Card. digital wallets are key.' AS business_relevance 
FROM payment_mode WHERE rn = 1

UNION ALL

SELECT 
    'Shipping Preference Mode'                              AS attribute, 
    val || ' (' || CAST(ROUND(cnt * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS VARCHAR) || '%)' AS value, 
    'Express delivery options dominate, suggesting speed and convenience are valued.' AS business_relevance 
FROM shipping_mode WHERE rn = 1

UNION ALL

SELECT 
    'Top State Location'                                    AS attribute, 
    val || ' (' || CAST(ROUND(cnt * 100.0 / (SELECT COUNT(*) FROM icp_base), 1) AS VARCHAR) || '%)' AS value, 
    'Maryland is the leading state, followed by Arizona and Tennessee.' AS business_relevance 
FROM location_mode WHERE rn = 1;

-- =============================================================================
-- END OF Q5
-- ALL SQL QUERIES COMPLETE. READY FOR PIPELINE INTEGRATION AND EXPORT.
-- =============================================================================
