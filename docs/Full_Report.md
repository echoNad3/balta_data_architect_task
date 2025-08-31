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
