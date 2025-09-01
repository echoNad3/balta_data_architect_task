# Answers

This README mirrors the structure of the assignment tasks in order.

---

## Repository

**1.** Create a Git repo (Bitbucket/GitHub/other).  
✅ Done. The project lives in a GitHub repo with a clean commit history. The local working folder is:  
`C:\Users\kzaum\Documents\Career\Homework\balta_data_architect_task`

**2.** Organize code by folders (`dbt`, `pipelines`, `docs`).  
✅ Done. Final structure:
- `dbt/` – dbt project (models, seeds, profiles, warehouse)  
- `pipelines/` – Python scripts (`validate_data.py`, `offers_uniqueness.py`, `export_for_pbi.py`)  
- `docs/` – documentation (this file, Full_Report.md, pipeline diagram), plus `docs/validation_report.md`  
- `exports/` – CSV exports for Power BI  

---

## GenAI

**1.** LLM usage must be documented.  
✅ Documented in README: used ChatGPT to scaffold dbt/Python, brainstorm dimensional design and counting strategy, and draft documentation; all code was validated locally.

---

## Datu ielāde un transformācija (ETL)

### 1. Medallion with dbt (locally)

**1.a** Build **fact_claims** (claims + policies join).  
✅ Implemented as `dbt/models/gold/fact_claims.sql`. level = **claim**.  

**1.b** Build **dim_customers**.  
✅ Implemented as `dbt/models/gold/dim_customers.sql`.

**1.c** What **new dimensions** can be derived from **customers**?  
✅ `age_group`, `age_years`.

**1.d** Build **dim_products** from **policies**.  
✅ Implemented as `dbt/models/gold/dim_products.sql`.  

**1.e** What **new dimensions** can be derived from **policies**?  
✅ `total_policy_term_days`, `days_till_policy_expiry`, `elapsed_policy_days`.

---

### 2. Business logic

**2.a** Compute **earned_premium** for each policy.  
✅ Implemented in `dbt/models/gold/fct_policy_premium.sql`:  
`earned_premium = written_premium * elapsed_days / total_days` 

**2.b** Compute **Claim Ratio** = Σ(claim_amount) / Σ(earned_premium).  
✅ Implemented as `dbt/models/gold/mart_claim_ratio_by_product.sql` and DAX measure in Power BI.  

**2.c Optimized SQL for average premium and average claim by customer age groups**  
✅ Implemented as `dbt/models/gold/mart_avg_by_age_group.sql`.
Age groups taken from `dbt/models/gold/dim_customers.sql`.


**2.d** Counting strategy when logic differs by product.  
✅ Different products use different counting rules, for example, AUTO counts vehicles, HOME counts risk objects, TRAVEL counts policies. Adding them together directly makes no sense. The best solution is to keep the fact table consistent (for example, one row per policy) and use a small mapping that tells the system which counting rule applies for each product. This way reports show the right counts for every product type.

Example:
| policy_id | product | vehicles | risks | amt_written_premium |
|-----------|---------|----------|-------|---------------------|
| P1        | AUTO    | 2        | NULL  | 100                 |
| P2        | HOME    | NULL     | 3     | 200                 |
| P3        | TRAVEL  | NULL     | NULL  | 50                  |

Answer: total of 6 (2 + 3 + 1) instead of just 3 policies.

---

## 3. Python integrācija

**3.a** Script for **data validation**.  
✅ `pipelines/validate_data.py` → `docs/validation_report.md`. 
Checks:
- Duplicate policies  
- End < Start dates  
- Claims without a matching policy from policy table
- Missing/implausible birth dates  
- Claims outside coverage window

**3.b** Script for **uniqueness in offers**.  
✅ `pipelines/offers_uniqueness.py` → flags `is_unique_day/week/month`. Output: `exports/offers_with_uniqueness.csv`.
➡️ Compares each offer to the next one in time, flagging it as unique if no later offer exists in the same window. 
This prevents double-counting and gives accurate daily, weekly, and monthly unique offer counts.

**3.c** Is Python the most efficient way? Alternatives?  
✅ Python is fine for moderate data. For scale, use SQL window functions (`LEAD()`, date diffs) inside dbt/warehouse.

---

## 4. Validate customers vs policies & claims

✅ dbt singular tests confirm:  
- Policies link to existing customers.  
- Customer dates plausible.  
Weaknesses observed:  
- Missing birth dates.  
- Implausible ages (guarded by test).  
- Free-text fields not standardized.  
- Claims inside coverage skipped (late-reported claims common, no `loss_date`).

---

## 5. CI/CD (Azure pipeline sketch)

✅ 
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
  ```

---

## 6. Power BI Semantic Model

**6.a.i** Link claims with policy dimensions.  
✅ Star schema:  
- `dim_customers (1) → fact_claims (*)` & `fct_policy_premium (*)`  
- `dim_products (1) → fact_claims (*)` & `fct_policy_premium (*)`  
ℹ️ Claims are linked to **policy-derived dimensions** via `dim_products` and attributes in `fct_policy_premium`.  
Additional policy dims (e.g. `dim_policy_status`, `dim_sales_channel`) are outlined and can be materialized if required.

**6.a.ii** Create measures (Claim Ratio, Total Premiums, Total Claims, Total Earned Premium).  
✅ Implemented:  
```DAX
Total Premiums (Written) := SUM ( fct_policy_premium[amt_written_premium] )
Total Earned Premium := SUM ( fct_policy_premium[amt_earned_premium] )
Total Claims := SUM ( fact_claims[amt_claim] )
Claim Ratio := DIVIDE ( [Total Claims], [Total Earned Premium] )
```

**6.b** Demonstrate model with mock-up.  
✅ Power BI report includes:
- **4 KPI cards**: *Total Claims*, *Total Written Premium*, *Total Earned Premium*, *Claim Ratio (%)*.
- **Bar/Column chart**: *Claim Ratio by Product* (axis = `product_code`).
- **Optional slicers**: *Customer Segment* and/or *Age Group* to demonstrate slicing.

---

## Naming Standards

✅ Adopted the provided standard across the project:

- **IDs:** `idd_*` (e.g., `idd_cus_customer`, `idd_pol_policy`, `idd_prd_product`)
- **Dates / Times:** `d_*` (date), `dt_*` (timestamp), `t_*` (time)
- **Amounts / Quantities / Counts:** `amt_*`, `qty_*`, `cnt_*`
- **Flags:** `is_*`
- **Attributes:** suffixes like `_code`, `_name`, `_descr` where relevant
- **Schemas (enterprise guidance):**  
  - `dwh` – core BI (dimensions & facts)  
  - `dwh_conf` – configuration / mapping tables  
  - `dwh_hist` – history tracking  
  - `staging_%`, `staging_%__hist` – raw staging + history per source  
  - `key_%` – key mapping helpers  

*(For this local DuckDB demo, a single physical schema is used, but column naming follows the standard.)*

---

## Runbook

**Setup**
- Create & activate Python venv (3.11).  
- Install dependencies: `dbt-duckdb`, `pandas`, `duckdb`, `pyarrow`, `tabulate`.

**dbt (from `./dbt`)**
- `dbt debug`  
- `dbt seed`  
- `dbt run` (builds Silver → Gold → marts)  
- `dbt test` (schema + custom tests)

**Python checks (from repo root)**
- `python pipelines/validate_data.py` → `docs/validation_report.md`  
- `python pipelines/offers_uniqueness.py` → `exports/offers_with_uniqueness.csv`  
- `python pipelines/export_for_pbi.py` → exports 5 CSVs for Power BI

**Power BI**
- Import the 5 CSVs from `/exports`.  
- Ensure **1→*** relationships from `dim_customers` & `dim_products` to both facts.  
- Add measures: *Total Claims*, *Total Written Premium*, *Total Earned Premium*, *Claim Ratio (%)*.  
- Build the 4 KPI cards + Claim Ratio by product chart; add optional slicers.

---

## Notes

- **Policy versions:** `stg_policies` keeps the **latest** `policy_version` per `policy_id` to ensure uniqueness and simplify joins (resolved a failing uniqueness test).  
- **Earned Premium:** computed via elapsed-days proration; uses `vars.as_of_date` (defaults to run date) for deterministic rebuilds.  
- **Claims in coverage window:** treated as **optional**; in real insurance data late-reported claims are common and the dataset lacks `loss_date`, so enforcing a strict window can yield false positives. Documented the decision and skipped enforcing it in CI.
