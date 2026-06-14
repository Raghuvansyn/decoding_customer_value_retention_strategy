# Loyalty Framework Design

> **Constraint:** No timestamps, no churn labels. Both frameworks are constructed entirely from available columns.  
> **Requirement (per brief):** At least two competing definitions, both tested, one argued for with evidence.

---

## Framework A — Tenure-Only (Single Signal)

### 1. Variables Used

| Variable | Source | Role |
|---|---|---|
| `Previous Purchases` | Raw column (integer, 1–50) | Sole input |
| `tenure_score` | Derived: `Previous Purchases ÷ 50` | Normalised form (0–1) |

### 2. Scoring Methodology

Each customer receives a score equal to their `tenure_score`:

```
Score_A = Previous Purchases / 50
```

Customers are then ranked by `Score_A` across the full population and assigned to percentile-based tiers.

### 3. Thresholds

| Percentile Range | `Previous Purchases` Equivalent | Score_A Range |
|---|---|---|
| Top 25% | 38–50 | 0.76–1.00 |
| Middle 50% | 14–37 | 0.28–0.74 |
| Bottom 25% | 1–13 | 0.02–0.26 |

### 4. Segment Definitions

| Segment | Criteria | Label |
|---|---|---|
| **High Loyalty** | Score_A ≥ 0.76 (top quartile) | "Loyalist" |
| **Medium Loyalty** | 0.28 ≤ Score_A < 0.76 | "Developing" |
| **Low Loyalty** | Score_A < 0.28 | "Casual" |

Expected size: ~975 Loyalists · ~1,950 Developing · ~975 Casual (by design of percentile split).

### 5. Advantages

- **Fully traceable.** One variable, one formula — every segment label maps back unambiguously to a data field.
- **Immune to subjective weighting.** No design choices that could be challenged.
- **Useful as a benchmark.** Establishes a clean baseline against which Framework B's complexity is justified.
- **SQL-simple.** `NTILE(4) OVER (ORDER BY previous_purchases)` — no ambiguity in implementation.

### 6. Limitations

- **Ignores margin quality.** A customer with 40 previous purchases — all under discount — scores identically to one with 40 purchases at full price. The most commercially important distinction is invisible.
- **Ignores voluntary commitment.** Subscription status is unused. A subscriber with 15 purchases scores below a non-subscriber with 38 purchases, despite the subscriber being more strategically valuable.
- **Uniform distribution problem.** `Previous Purchases` is near-uniformly distributed (1–50, avg 25.35). Percentile splits are therefore almost exactly equal in size — the tiers carry little discriminative signal. A 37-purchase customer and a 38-purchase customer are in different tiers despite being effectively identical.
- **Cannot answer the core question.** Framework A cannot distinguish between organic loyalty and discount-induced repeat behaviour — which is the business's primary strategic question.

---

## Framework B — Multi-Signal Composite

### 1. Variables Used

| Variable | Source | Weight | Rationale |
|---|---|---|---|
| `tenure_score` | `Previous Purchases ÷ 50` | **50%** | Tenure is necessary but not sufficient for loyalty |
| `subscription_flag` | `1` if Subscribed, else `0` | **30%** | Voluntary programme commitment — strongest available signal of genuine brand affiliation |
| `no_discount_flag` | `1` if `Discount Applied = No`, else `0` | **20%** | Purchasing at full price signals intrinsic brand preference, not promo response |

### 2. Scoring Methodology

```
Score_B = (tenure_score × 0.50)
        + (subscription_flag × 0.30)
        + (no_discount_flag × 0.20)
```

Score range: 0.00 (lowest) to 1.00 (highest).  
Score is then scaled to 0–100 for readability: `Loyalty_B = Score_B × 100`.

**Worked examples:**

| Profile | Previous Purchases | Subscribed | No Discount | Score_B | Loyalty_B |
|---|---|---|---|---|---|
| Full-price subscriber, high tenure | 45 | Yes | Yes | (0.90×0.5)+(1×0.3)+(1×0.2) = **0.95** | **95** |
| Discount-only buyer, high tenure | 45 | No | No | (0.90×0.5)+(0×0.3)+(0×0.2) = **0.45** | **45** |
| Subscriber, low tenure, no discount | 10 | Yes | Yes | (0.20×0.5)+(1×0.3)+(1×0.2) = **0.60** | **60** |
| No sub, no discount, low tenure | 8 | No | Yes | (0.16×0.5)+(0×0.3)+(1×0.2) = **0.28** | **28** |

This illustrates the core separation Framework A cannot achieve: a 45-purchase discount buyer (Score 45) is correctly ranked below a 10-purchase subscriber with no discounts (Score 60).

### 3. Thresholds

| Loyalty_B Score | Interpretation |
|---|---|
| **≥ 65** | High Loyalty |
| **35–64** | Medium Loyalty |
| **< 35** | Low Loyalty |

Threshold rationale:
- 65 requires either: high tenure + subscription, or high tenure + no discount + subscription. It excludes high-tenure discount-only buyers — by design.
- 35 is the approximate score of a mid-tenure, non-subscribed, discounted customer — the floor for "developing" status.

### 4. Segment Definitions

| Segment | Score_B Range | Label | Strategic Meaning |
|---|---|---|---|
| **High Loyalty** | Loyalty_B ≥ 65 | "Champion" | Protect, reward, profile for ICP |
| **Medium Loyalty** | Loyalty_B 35–64 | "Growth" | Convert to subscriber; test promo reduction |
| **Low Loyalty** | Loyalty_B < 35 | "Casual" | Do not invest in retention; optimise acquisition cost |

Validated distribution (based on SQL query verification):
- Champions: 603 customers (15.5%) — subscribed, high tenure, full-price buyers
- Growth: 2,146 customers (55.0%)
- Casual: 1,151 customers (29.5%)

### 5. Advantages

- **Answers the business question directly.** Separates margin-healthy repeat buyers from discount-dependent ones — the exact strategic question in the brief.
- **Three orthogonal signals.** Tenure, voluntary commitment, and price sensitivity each contribute unique information. No two are perfectly correlated.
- **Produces a traceable `promo_sunset_candidate` segment.** Customers with high tenure but low Score_B (due to discount dependency and no subscription) are precisely identifiable.
- **Aligned with the ICP deliverable.** The Champion segment can be directly described in demographic and behavioural terms — the marketing team has an immediately actionable profile.

### 6. Limitations

- **Weight choices are assumptive.** The 50/30/20 split is defensible but not empirically derived — the dataset has no revenue-per-customer or CLV column to validate weights against.
- **Subscription base is small.** Only 27% of customers are subscribed. Champions will be a minority segment — the brand must decide whether ICP = top 17% is actionable at scale.
- **`no_discount_flag` ambiguity.** The dataset cannot confirm whether discount absence reflects customer preference or brand decision. A customer may have wanted a discount but none was offered.
- **Still vulnerable to synthetic uniformity.** `tenure_score`'s 50% weight means the uniform distribution of `Previous Purchases` still dampens discriminative power. Mitigated but not eliminated.

---

## Head-to-Head Comparison

| Dimension | Framework A | Framework B |
|---|---|---|
| **Variables** | 1 | 3 |
| **Complexity** | Low | Moderate |
| **Traceability** | High | High |
| **Answers core business question** | No | Yes |
| **Separates discount buyers from loyalists** | No | Yes |
| **Identifies promo sunset candidates** | No | Yes |
| **Produces usable ICP** | Partially | Yes |
| **Sensitivity to synthetic data** | High | Moderate |
| **Weight subjectivity** | None | Present |
| **SQL implementation difficulty** | Trivial | Low |
| **Vulnerability to challenge** | Distribution uniformity | Weight assumptions |

---

## Final Recommendation

**Adopt Framework B as the primary loyalty definition.**

The brief's central strategic question is: *"Is the business building organic loyalty, or is it reliant on promotions?"* Framework A is structurally incapable of answering this — it treats a high-tenure discount buyer identically to a high-tenure full-price subscriber. Framework B was designed specifically to make that separation visible.

**How to defend against weight-subjectivity challenges (Sensitivity Analysis):**

The baseline weighting scheme (50/30/20) remains the preferred design. Sensitivity testing showed moderate responsiveness to alternative weighting structures, with tier membership shifts of 9.1% under a tenure-heavy model and 14.6% under a subscription-heavy model. This confirms that the chosen weights are active strategic decisions rather than interchangeable parameters.

*Methodology Note:* The feature-engineering pipeline rounds `loyalty_score_b` to two decimal places before tier assignment, whereas the sensitivity test evaluates raw floating-point scores. This creates a minor baseline discrepancy (approximately 0.44% of customers) and does not materially affect strategic findings.

**How to use Framework A:**

Retain as a benchmark. Where Framework A and Framework B produce the same tier assignment for a customer, that customer's classification is doubly confirmed. Where they diverge — specifically, high-tenure customers who score high on A but low on B — those are the `promo_sunset_candidate` targets: the most commercially important segment in the entire dataset.
