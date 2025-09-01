import pandas as pd
from pathlib import Path

root = Path(__file__).resolve().parents[1]
offers = pd.read_csv(root / "dbt/seeds/offers.csv", parse_dates=["offer_datetime"])

# Sort
keys = ["customer_id", "coverage_hash", "offer_datetime"]
offers = offers.sort_values(keys)

# Next offer time within each (customer_id, coverage_hash)
offers["next_dt"] = offers.groupby(["customer_id", "coverage_hash"])["offer_datetime"].shift(-1)

# Gap in days
gap_days = (offers["next_dt"] - offers["offer_datetime"]).dt.total_seconds() / 86400.0

# Flags
offers["is_unique_day"]   = ((gap_days.isna()) | (gap_days > 1)).astype("int8")
offers["is_unique_week"]  = ((gap_days.isna()) | (gap_days > 7)).astype("int8")
offers["is_unique_month"] = ((gap_days.isna()) | (gap_days > 30)).astype("int8")

offers = offers.drop(columns=["next_dt"])

out = root / "exports"
out.mkdir(exist_ok=True)
offers.to_csv(out / "offers_with_uniqueness.csv", index=False)
print(f"Saved -> {out/'offers_with_uniqueness.csv'}")
