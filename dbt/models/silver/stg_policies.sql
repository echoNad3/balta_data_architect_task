with src as (
  select * from {{ ref('policies') }}
),
ranked as (
  select
    *,
    row_number() over (
      partition by policy_id
      order by policy_version desc
    ) as rn
  from src
),
picked as (
  select * from ranked where rn = 1
)
select
  policy_id                                        as idd_pol_policy,
  customer_id                                      as idd_cus_customer,
  product_code,
  product_variant,
  cast(start_date     as date)                     as d_cov_start,
  cast(end_date       as date)                     as d_cov_end,
  policy_status,
  cast(written_premium as decimal(18,2))           as amt_written_premium,
  cast(sum_insured     as decimal(18,2))           as amt_sum_insured,
  currency,
  sales_channel
from picked