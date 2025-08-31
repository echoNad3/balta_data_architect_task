```mermaid
flowchart LR
  A[CSV files] --> B[dbt seed]
  B --> C[(Silver: stg_*)]
  C --> D[(Gold: dims)]
  C --> E[(Gold: facts)]
  D & E --> F[(Marts)]
  F --> G[Exports]
  G --> H[Power BI]
  H --> I[Tabular Editor / Measures]