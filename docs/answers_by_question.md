# Answers by Question (Uzdevums)

This document mirrors the structure of the assignment PDF so the assessor can quickly map each answer to the corresponding requirement.  

---

## Repozitorijs (Repository)

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

## GenAI (allowed if documented)

**1.** LLM usage must be documented.  
✅ Documented in README: used ChatGPT to scaffold dbt/Python, brainstorm dimensional design and counting strategy, and draft documentation; all code was validated locally.

---

## Datu ielāde un transformācija (ETL)

### 1. Medallion with dbt (locally)

**1.a** Build **fact_claims** (claims + policies join).  
✅ Implemented as `dbt/models/gold/fact_claims.sql`. Grain = **claim**.  

**1.b** Build **dim_customers**.  
✅ Implemented as `dbt/models/gold/dim_customers.sql`. Adds:  
- `age_years`  
- `age_group` buckets (00–17, 18–24, …, 65+)

**1.c** What **new dimensions** can be derived from **customers**?  
✅ Implemented: `dim_customers` with `age_group`.  
Other candidates: `dim_age_group`, `dim_geography`, `dim_customer_segment`.

**1.d** Build **dim_products** from **policies**.  
✅ Implemented as `dbt/models/gold/dim_products.sql`.  

**1.e** What **new dimensions** can be derived from **policies**?  
✅ Candidates: `dim_policy_status`, `dim_sales_channel`, `dim_currency`, `dim_policy_term`.

---

### 2. Business logic

**2.a** Compute **earned_premium** for each policy.  
✅ Implemented in `fct_policy_premium.sql`:  
`earned_premium = written_premium * elapsed_days / total_days`  
(Bounded, uses `vars.as_of_date`.)

**2.b** Compute **Claim Ratio** = Σ(claim_amount) / Σ(earned_premium).  
✅ Implemented via dbt mart + DAX measure in Power BI.  

**2.c Optimized SQL for average premium and average claim by customer age groups — implemented.**  
✅ Implemented in mart: pre-join facts to `dim_customers` age buckets, single aggregation step.  
(SQL example provided in Full_Report.md.)


**2.d** Counting strategy when logic differs by product.  
✅ Keep fact grain stable. Introduce config table mapping product → rule. dbt derives count cols (`cnt_policy`, `cnt_vehicle`, …). PBI measures select rule dynamically.

---

## 3. Python integrācija

**3.a** Script for **data validation**.  
✅ `pipelines/validate_data.py` → `docs/validation_report.md`. Checks:
- Duplicate policies  
- End < Start dates  
- Orphan claims  
- Missing/implausible birth dates  
- Optional: claims outside coverage  

**3.b** Script for **uniqueness in offers**.  
✅ `pipelines/offers_uniqueness.py` → flags `is_unique_day/week/month`. Output: `exports/offers_with_uniqueness.csv`.
➡️ The `UniqueDay` / `UniqueWeek` / `UniqueMonth` results are exposed as attributes on offers (functioning as dimensions).  
If preferred, they can be materialized as a small `dim_offer_uniqueness` (offer_id + three flags) and joined to facts.


**3.c** Is Python the most efficient way? Alternatives?  
✅ Pandas is fine for moderate data. For scale, use SQL window functions (`LEAD()`, date diffs) inside dbt/warehouse.

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

✅ Mermaid diagram in `docs/Full_Report.md`. Flow:  
CSV ingest → dbt seed → Silver → Gold (dims/facts) → marts → exports → Power BI.  
Real-world mapping: Files → ADF/Databricks → Lakehouse → dbt CI → PBI deploy.

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
