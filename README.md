# Decoding Customer Value — Retention Strategy

Customer analytics project for a D2C fashion brand. Uses SQL, Python, and Power BI to segment customers, quantify discount dependency, and build actionable retention strategies from transactional data.

## Problem Statement

The brand faces declining repeat purchase rates and growing reliance on promotional discounts. This project investigates customer behavior to answer five core business questions and deliver a data-driven retention framework.

## Business Questions

| # | Question | Approach |
|---|----------|----------|
| Q1 | How do loyal customers differ from promo-dependent buyers? | Behavioral segmentation using purchase patterns, discount ratios, and return rates |
| Q2 | What factors predict high customer lifetime value? | Feature importance analysis across RFM metrics, engagement signals, and spending behavior |
| Q3 | Where are the untapped geographic opportunities? | Regional performance benchmarking with penetration and growth rate analysis |
| Q4 | How should the promotion strategy be restructured? | Discount elasticity modeling and tier-based promo framework |
| Q5 | What does the ideal customer profile look like? | Composite scoring model combining loyalty, value, and engagement dimensions |

## Project Structure

```
.
├── data/
│   ├── Dataset (1).csv                 # Raw transactional data
│   ├── cleaned.csv                     # Cleaned and validated dataset
│   ├── features.csv                    # Engineered feature set
│   └── SQL.pdf                         # SQL reference documentation
│
├── sql/
│   ├── 00_base_view.sql                # Base analytical view (dependency for all queries)
│   ├── Q1_loyal_vs_promo_buyers.sql
│   ├── Q2_value_predictors.sql
│   ├── Q3_geo_opportunity.sql
│   ├── Q4_promo_restructure.sql
│   └── Q5_ideal_customer_profile.sql
│
├── docs/
│   ├── executive_summary.md            # C-suite findings overview
│   ├── project_analysis.md             # Full analytical deep-dive
│   ├── consulting_presentation.md      # Strategy recommendation deck
│   ├── loyalty_framework.md            # Loyalty scoring methodology
│   ├── feature_engineering_strategy.md # Feature design rationale
│   ├── retention_playbook.md           # Segment-specific retention tactics
│   ├── implementation_roadmap.md       # 12-month phased rollout plan
│   ├── powerbi_dashboard_specification.md
│   ├── presentation_structure.md
│   └── decoding_customer_value_presentation.pptx
│
├── powerbi/
│   └── theme.json                      # Custom Power BI dashboard theme
│
└── reports/
    └── framework_sensitivity.csv       # Sensitivity analysis output
```

## Methodology

**Data Pipeline**: Raw transactions → cleaning and validation → feature engineering (40+ features across RFM, behavioral, and engagement dimensions)

**Segmentation Framework**: Multi-dimensional customer scoring using weighted composites of:
- Purchase frequency and recency
- Full-price vs. discounted purchase ratio
- Return behavior and order consistency
- Geographic and channel engagement signals

**SQL Approach**: All five analyses are built on a shared base view (`00_base_view.sql`) using CTEs, window functions, and conditional aggregations. Each query is self-contained and documented.

## Key Deliverables

- **Executive Summary** — High-level findings and strategic recommendations
- **Retention Playbook** — Actionable tactics mapped to each customer segment
- **Implementation Roadmap** — Phased plan with KPIs and ownership assignments
- **Power BI Dashboard Spec** — Interactive reporting design for ongoing monitoring
- **Consulting Presentation** — Full strategy deck for stakeholder review

## Tools Used

- **SQL** — Analytical queries, window functions, CTEs, conditional aggregation
- **Python** — Data cleaning, feature engineering, exploratory analysis
- **Power BI** — Dashboard design with custom theming
- **Markdown / PowerPoint** — Documentation and stakeholder presentations

## How to Use

1. Start with `sql/00_base_view.sql` to create the base analytical view
2. Run the Q1–Q5 queries in any order against the base view
3. Review `docs/project_analysis.md` for the full analytical narrative
4. See `docs/retention_playbook.md` for actionable recommendations

## License

This project is for educational and portfolio purposes.
