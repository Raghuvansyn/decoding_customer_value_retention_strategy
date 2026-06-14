# Feature Engineering Strategy

> **Source columns only.** No external data. All features derived from the 18 raw fields.  
> **Constraint acknowledged:** No timestamps. `Previous Purchases` (1–50) is the sole tenure proxy.

---

## Engineered Features

| # | Feature Name | Formula (Plain Logic) | Purpose |
|---|---|---|---|
| 1 | `tenure_score` | `Previous Purchases` normalised to 0–1 scale (value ÷ 50) | Converts raw purchase count into a bounded loyalty signal usable in both frameworks and all segments. Anchors every loyalty and value calculation. |
| 2 | `discount_dependent` | `1` if `Discount Applied = Yes`, else `0` | Binary flag marking whether the customer purchased under promotional conditions. Core input to Framework A and the promo sunset targeting logic. |
| 3 | `subscription_flag` | `1` if `Subscription Status = Yes`, else `0` | Binary indicator of voluntary programme commitment — the cleanest available signal of deliberate brand affiliation. Used in Framework B composite. |
| 4 | `loyalty_score_A` | `tenure_score` — percentile rank of `Previous Purchases` across all customers, binned: top 25% = High, 25–75% = Medium, bottom 25% = Low | **Framework A** (tenure-only definition). Simple, traceable, single-variable. Baseline against which Framework B is compared. |
| 5 | `loyalty_score_B` | Weighted composite: `(tenure_score × 0.5) + (subscription_flag × 0.3) + ((1 − discount_dependent) × 0.2)`, normalised 0–100, binned: ≥ 65 = High, 35–64 = Medium, < 35 = Low | **Framework B** (multi-signal definition). Rewards tenure, voluntary commitment, and independence from promotions simultaneously. More decision-relevant than A alone. |
| 6 | `value_tier` | Derived from `loyalty_score_B` bins: High → "Champion", Medium → "Growth", Low → "Casual" | Segment label used in the customer pyramid dashboard panel and all downstream SQL queries. Must map to a specific, stated combination of variables (per brief requirement). |
| 7 | `satisfaction_flag` | `Review Rating ≥ 4.3` → "Satisfied"; `3.5–4.2` → "Neutral"; `< 3.5` → "At Risk"; `null` → imputed with category-level median before flagging | Proxy for retention risk. Satisfied customers in low-loyalty tiers are upgrade candidates; At Risk customers in any tier signal churn pressure. Used in retention playbook prioritisation. |
| 8 | `frequency_score` | Convert `Frequency of Purchases` text to numeric: Weekly = 7, Bi-Weekly = 3.5, Fortnightly = 3.5, Monthly = 2, Quarterly = 1, Every 3 Months = 0.75, Annually = 0.5 | Enables quantitative comparison of purchase cadence across customers. Cross-validated against `Previous Purchases` to flag internally inconsistent self-reports. |
| 9 | `high_value_confirmed` | `1` if `loyalty_score_B ≥ 65` AND `frequency_score ≥ 2` (i.e., monthly or faster), else `0` | Dual-validation loyalty flag: only customers whose composite score and self-reported cadence are mutually consistent are marked confirmed high-value. Reduces noise from synthetic uniformity in either variable alone. |
| 10 | `promo_sunset_candidate` | `1` if `discount_dependent = 1` AND `subscription_flag = 0` AND `Previous Purchases ≥ 35`, else `0` | Identifies the specific segment for promo reduction: frequent buyers who still rely on discounts and have not converted to subscription. The target group for the sunset rollout. |
| 11 | `geo_demand_type` | Per state: if state discount rate < overall avg (43%) AND state customer count ≥ overall avg → "Organic Pull"; if discount rate ≥ avg AND count ≥ avg → "Discount Pull"; remaining → "Underdeveloped" | Classifies each state's demand quality for the geographic opportunity dashboard panel. Built from `Location` + `discount_dependent` aggregate. |

---

## Feature-to-Use Mapping

| Feature | Framework A | Framework B | Segmentation | Retention Playbook |
|---|---|---|---|---|
| `tenure_score` | ✓ | ✓ | ✓ | — |
| `discount_dependent` | — | ✓ | ✓ | ✓ |
| `subscription_flag` | — | ✓ | ✓ | ✓ |
| `loyalty_score_A` | **Primary** | Benchmark | — | — |
| `loyalty_score_B` | Benchmark | **Primary** | ✓ | ✓ |
| `value_tier` | — | — | **Primary** | ✓ |
| `satisfaction_flag` | — | — | ✓ | ✓ |
| `frequency_score` | — | — | ✓ | ✓ |
| `high_value_confirmed` | — | — | ✓ | ✓ |
| `promo_sunset_candidate` | — | — | — | **Primary** |
| `geo_demand_type` | — | — | ✓ | — |

---

## Why Framework B Wins

Framework A (`loyalty_score_A`) depends entirely on `Previous Purchases`, which is uniformly distributed 1–50 — a likely synthetic artefact. A customer ranked in the top 25% has 38–50 previous purchases, but the 0.68-purchase average difference between discount users and non-users means purchase count alone cannot distinguish margin-healthy customers from discount-dependent ones.

Framework B (`loyalty_score_B`) adds two orthogonal signals — voluntary subscription commitment and absence of promo dependency — that purchase count cannot capture. A customer with 40 purchases, no subscription, and every order discounted scores differently from one with 40 purchases, subscribed, and zero discounts used. That distinction is the entire strategic question the brand is asking.

**Framework B is adopted as the primary loyalty definition for all downstream SQL, dashboard, and playbook work.**
