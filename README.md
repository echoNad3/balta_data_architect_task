# Balta Data Architect Take-Home – Summary

## 🚀 Setup
- Python venv created in repo root.  
- Installed: `dbt-duckdb`, `pandas`, `duckdb`, `pyarrow`, `tabulate`.  
- dbt project lives in `/dbt`, using local DuckDB (`dbt/warehouse/balta.duckdb`).  
- Raw CSVs seeded via `dbt seed`.

---

## 🧱 Modeling (Medallion in dbt)
- **Silver**: staging for customers, policies (latest version per policy), claims, offers.  
- **Gold**:  
  - `dim_customers` → adds `age_years` + `age_group`.  
  - `dim_products` → product code + variant.  
  - `fact_claims` → claim-level fact with FKs.  
  - `fct_policy_premium` → written & **earned premium** (prorated by elapsed coverage days).

---

## 📊 Business Logic
- **Earned Premium** = `written_premium * elapsed_days / total_days`.  
- **Claim Ratio** = ΣClaims / ΣEarned Premium (by product).  
- **Average premium & claim by age group** mart.  
- **Counting strategy**: fact grain stable + config table for product-specific counts.

---

## ✅ Data Quality
- dbt schema tests: uniqueness, not_null, relationships.  
- Policy deduplication (latest version) resolved duplicates.  
- Cross-table tests: policies link to customers, valid customer dates.  
- Profiling: missing birth dates, city/segment inconsistencies.  
- Claims outside coverage not enforced (late reporting possible).

---

## 🐍 Python Checks
- `validate_data.py` → duplicates, date issues, orphan claims, missing values.  
- `offers_uniqueness.py` → last unique offers in 24h/7d/30d per customer + coverage.  
- Exports: `offers_with_uniqueness.csv`.

---

## 🔄 CI/CD Sketch
CSV ingest → dbt seeds → Silver → Gold (dims/facts) → marts → exports → Power BI semantic model.  
(See diagram in [docs/Full_Report.md](docs/Full_Report.md))  

---

## 📈 Power BI Semantic Model
- **Star schema**: `dim_customers` + `dim_products` (1→*) → facts.  
- **Measures**:  
  - `Total Claims`  
  - `Total Written Premium`  
  - `Total Earned Premium`  
  - `Claim Ratio` (%)  
- **Mock dashboard**: 4 KPI cards + bar chart of Claim Ratio by product + optional slicers.

---

## 📦 Deliverables
- dbt project (Silver/Gold + marts).  
- Earned Premium + Claim Ratio logic.  
- Python DQ + offers uniqueness scripts.  
- Data profiling notes.  
- CI/CD sketch.  
- Power BI model + mock dashboard.

---

🔎 For full details, see [docs/Full_Report.md](docs/Full_Report.md).
