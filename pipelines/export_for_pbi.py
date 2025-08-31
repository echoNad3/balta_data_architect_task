# pipelines/export_for_pbi.py
import duckdb, pandas as pd
from pathlib import Path

root = Path(__file__).resolve().parents[1]
db = root/"dbt/warehouse/balta.duckdb"
out = root/"exports"; out.mkdir(exist_ok=True)
con = duckdb.connect(str(db))

for tbl in ["dim_customers","dim_products","fact_claims","fct_policy_premium","mart_claim_ratio_by_product"]:
    df = con.execute(f"select * from {tbl}").fetchdf()
    df.to_csv(out/f"{tbl}.csv", index=False)

print("Exported CSVs to exports/")
