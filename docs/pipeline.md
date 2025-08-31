flowchart LR
  A[CSV files\n(customers, policies, claims, offers)] --> B[dbt seed (DuckDB)]
  B --> C[(Silver: stg_* )]
  C --> D[(Gold: dim_customers, dim_products)]
  C --> E[(Gold: fact_claims, fct_policy_premium)]
  D & E --> F[(Marts: claim_ratio_by_product, avg_by_age_group)]
  F --> G[Export CSVs -> exports/]
  G --> H[Power BI Desktop]
  H --> I[Tabular Editor measures]
