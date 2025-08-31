{% set as_of_date = var('as_of_date', run_started_at.strftime('%Y-%m-%d')) %}

with pol as (
  select p.*, d.idd_prd_product
  from {{ ref('stg_policies') }} p
  left join {{ ref('dim_products') }} d
    on d.product_code = p.product_code and d.product_variant = p.product_variant
),
calc as (
  select
    idd_pol_policy,
    idd_cus_customer,
    idd_prd_product,
    d_cov_start,
    d_cov_end,
    amt_written_premium,
    -- total coverage days (inclusive)
    1 + date_diff('day', d_cov_start, d_cov_end)                            as cov_days_total,
    -- elapsed days up to as_of_date (bounded to [0, cov_days_total])
    case
      when cast('{{ as_of_date }}' as date) < d_cov_start then 0
      when cast('{{ as_of_date }}' as date) >= d_cov_end then 1 + date_diff('day', d_cov_start, d_cov_end)
      else 1 + date_diff('day', d_cov_start, cast('{{ as_of_date }}' as date))
    end as cov_days_elapsed
  from pol
)
select
  idd_pol_policy,
  idd_cus_customer,
  idd_prd_product,
  d_cov_start, d_cov_end,
  amt_written_premium,
  cast(nullif(cov_days_total,0) as double)                                 as cov_days_total,
  cov_days_elapsed,
  round(amt_written_premium * cov_days_elapsed / nullif(cov_days_total,0), 2) as amt_earned_premium
from calc