# Balta Data Architect Take-Home – Full Report

## 📑 Table of Contents
1. [Environment & Setup](#1-environment--setup)  
2. [Medallion Modeling (dbt)](#2-medallion-modeling-dbt)  
   - [New dimensions from Customers](#new-dimensions-from-customers)  
   - [New dimensions from Policies](#new-dimensions-from-policies)  
3. [Business Logic](#3-business-logic)  
   - [Earned Premium](#earned-premium)  
   - [Claim Ratio](#claim-ratio)  
   - [Average Premium & Claim by Age Group](#average-premium--claim-by-age-group)  
   - [Counting Strategy](#counting-strategy)  
4. [Data Quality & Profiling](#4-data-quality--profiling)  
5. [Python Integration](#5-python-integration)  
6. [CI/CD Pipeline Sketch](#6-cicd-pipeline-sketch)  
7. [Power BI Semantic Model](#7-power-bi-semantic-model)  
8. [Naming Standards](#8-naming-standards)  
9. [Deliverables](#9-deliverables)  
10. [GenAI Use](#10-where-genai-helped)  
11. [Next Steps](#11-possible-next-steps)

---

## 1. Environment & Setup
- venv + dbt-duckdb installed.  
- Warehouse at `dbt/warehouse/balta.duckdb`.  
- Seeds: customers, policies, claims, offers.  
- Commands: `dbt seed`, `dbt run`, `dbt test`.

---

## 2. Medallion Modeling (dbt)

**Silver layer**  
- `stg_customers` (birth_date, created_at, base attrs)  
- `stg_policies` (dedup by policy_version, amounts, dates)  
- `stg_claims` (typed)  
- `stg_offers` (timestamp + hash)

**Gold layer**  
- `dim_customers` (age, age_group)  
- `dim_products` (product_code + variant key)  
- `fact_claims` (grain = claim)  
- `fct_policy_premium` (grain = policy; written + earned premium)

### New dimensions from Customers
- Age group (00–17, …, 65+)  
- Geography (city/country)  
- Segment (Retail/SME/Corporate)

### New dimensions from Policies
- Product (built)  
- Policy Status, Sales Channel, Currency, Policy Term

---

## 3. Business Logic

### Earned Premium
`written_premium * elapsed_days / total_days` (bounded, uses `as_of_date` var)

### Claim Ratio
Σ(Claims) / Σ(Earned Premium), aggregated by product.

### Average Premium & Claim by Age Group
Mart implemented via join to `dim_customers` age buckets.

### Counting Strategy
Stable fact grain; config table mapping product → rule; dbt derived counts; PBI measures select rule. Prevents double-counting.

---

## 4. Data Quality & Profiling
- dbt schema tests: unique, not_null, relationships.  
- Dedup policies by version.  
- Custom tests: policies→customers, customer date validity.  
- Profiling found missing birth dates, implausible ages, inconsistent free-texts.  
- Claims vs coverage test considered but skipped (late reporting).  

---

## 5. Python Integration
- `validate_data.py` → duplicate policies, invalid dates, orphan claims, missing births. Output: `docs/validation_report.md`.  
- `offers_uniqueness.py` → flags last offer in 24h/7d/30d window per customer+coverage. Output: `exports/offers_with_uniqueness.csv`.  
- Efficiency: Pandas good for demo; production should use SQL windowing for scale.

---

## 6. CI/CD Pipeline Sketch

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


## 7. Power BI Semantic Model
- **Star schema**:  
  - `dim_customers` (1 → *) → `fact_claims` and `fct_policy_premium`  
  - `dim_products` (1 → *) → `fact_claims` and `fct_policy_premium`  
- Relationships are **single-direction filters** from dimensions to facts, all active.  
- **Measures (DAX):**

    ```DAX
    Total Claims := SUM ( fact_claims[amt_claim] )

    Total Written Premium := SUM ( fct_policy_premium[amt_written_premium] )

    Total Earned Premium := SUM ( fct_policy_premium[amt_earned_premium] )

    Claim Ratio := DIVIDE ( [Total Claims], [Total Earned Premium] )
    ```

- **Claim Ratio** is formatted as Percentage.  
- **Mock report**:  
  - 4 KPI cards (Total Claims, Total Written Premium, Total Earned Premium, Claim Ratio).  
  - Bar chart of Claim Ratio by Product Code.  
  - Optional slicers (e.g. Segment, Age Group).

---

## 8. Naming Standards
- **Column conventions:**  
  - IDs → `idd_*` (e.g. `idd_cus_customer`, `idd_pol_policy`)  
  - Dates → `d_*` (date) / `dt_*` (timestamp)  
  - Amounts → `amt_*` (monetary)  
  - Flags → `is_*`  
- **Schemas (per enterprise standard):**  
  - `dwh` – core BI (dims/facts)  
  - `dwh_conf` – configuration/mapping tables  
  - `dwh_hist` – history tracking  
  - `staging_%`, `staging_%__hist` – raw staging + history  
  - `key_%` – key mapping helpers  
*(Locally in DuckDB I used one schema, but the names above align with enterprise guidance.)*

---

## 9. Deliverables
- dbt project with Silver/Gold + marts.  
- Business logic: Earned Premium, Claim Ratio.  
- Python pipelines: data validation + offers uniqueness.  
- Data profiling & weaknesses documented.  
- CI/CD pipeline sketch (Mermaid diagram).  
- Power BI semantic model + mock dashboard.  
- Applied naming & schema standards.

---

## 10. Where GenAI helped
I used ChatGPT for:  
- Drafting dbt SQL and Python scaffolding.  
- Brainstorming new dimensions & counting strategy.  
- Drafting this documentation.  
All outputs were validated and executed locally.

---

## 11. Possible Next Steps
- Add calendar/date dimension for YTD, MoM, rolling averages.  
- Deploy pipeline in Azure (ADF/Databricks/dbt Cloud + CI/CD).  
- More robust DQ checks (normalize city, gender, segment values).  
- Move offers uniqueness calculation to SQL with window functions for scalability.
