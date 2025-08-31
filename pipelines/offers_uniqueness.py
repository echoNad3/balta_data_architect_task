# pipelines/offers_uniqueness.py
import pandas as pd
from pathlib import Path

root = Path(__file__).resolve().parents[1]
offers = pd.read_csv(root/"dbt/seeds/offers.csv",
                     parse_dates=["offer_datetime"])

offers = offers.sort_values(["customer_id","coverage_hash","offer_datetime"])
grp = offers.groupby(["customer_id","coverage_hash"], group_keys=False)

def flag_unique(g, days: int, colname: str):
    # compare each row to the *next* row in the same group
    next_time = g["offer_datetime"].shift(-1)
    # unique = there is no later offer within the window
    g[colname] = ((next_time.isna()) |
                  ((next_time - g["offer_datetime"]).dt.total_seconds() > days*24*3600)).astype(int)
    return g

offers = grp.apply(flag_unique, days=1,  colname="is_unique_day")
offers = grp.apply(flag_unique, days=7,  colname="is_unique_week")
offers = grp.apply(flag_unique, days=30, colname="is_unique_month")

out = root/"exports"
out.mkdir(exist_ok=True)
offers.to_csv(out/"offers_with_uniqueness.csv", index=False)
print(f"Saved -> {out/'offers_with_uniqueness.csv'}")
