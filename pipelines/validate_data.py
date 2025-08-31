# pipelines/validate_data.py
import pandas as pd
from pathlib import Path

root = Path(__file__).resolve().parents[1]
seeds = root / "dbt" / "seeds"
out   = root / "docs"
out.mkdir(exist_ok=True)

claims   = pd.read_csv(seeds/"claims.csv", parse_dates=["claim_date"])
policies = pd.read_csv(seeds/"policies.csv", parse_dates=["start_date","end_date"])
customers= pd.read_csv(seeds/"customers.csv", parse_dates=["birth_date","created_at"])

report = []

# 1) duplicate policy_id
dup_policies = policies[policies.duplicated("policy_id", keep=False)]
report.append(f"Duplicate policy_id rows: {len(dup_policies)}")

# 2) policy end before start
bad_period = policies[policies["end_date"] < policies["start_date"]]
report.append(f"Policies with end_date < start_date: {len(bad_period)}")

# 3) FK: claims pointing to missing policies
missing_fk = claims[~claims["policy_id"].isin(policies["policy_id"])]
report.append(f"Claims with unknown policy_id: {len(missing_fk)}")

# 4) claim_date outside policy coverage (optional quality rule)
merged = claims.merge(policies[["policy_id","start_date","end_date"]], on="policy_id", how="left")
outside = merged[(merged["claim_date"] < merged["start_date"]) | (merged["claim_date"] > merged["end_date"])]
report.append(f"Claims outside policy coverage window: {len(outside)}")

# 5) simple customer quality ideas
cust_na_birth = customers["birth_date"].isna().sum()
report.append(f"Customers with missing birth_date: {cust_na_birth}")

with open(out/"validation_report.md","w",encoding="utf-8") as f:
    f.write("# Data Quality Report\n\n")
    f.write("\n".join(f"- {line}" for line in report))
    f.write("\n\nExamples (first 10):\n")
    f.write("\n\n## Duplicates in policies\n")
    f.write(dup_policies.head(10).to_markdown(index=False))
    f.write("\n\n## Claims outside coverage\n")
    f.write(outside.head(10).to_markdown(index=False))

print("\n".join(report))
print(f"Report -> {out/'validation_report.md'}")
