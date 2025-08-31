with claims as (
  select idd_prd_product, sum(amt_claim) as amt_total_claims
  from {{ ref('fact_claims') }}
  group by 1
),
prem as (
  select idd_prd_product,
         sum(amt_earned_premium)  as amt_total_earned_premium,
         sum(amt_written_premium) as amt_total_written_premium
  from {{ ref('fct_policy_premium') }}
  group by 1
)
select
  prd.idd_prd_product,
  prd.product_code,
  prd.product_variant,
  coalesce(c.amt_total_claims, 0)           as amt_total_claims,
  coalesce(p.amt_total_earned_premium, 0)   as amt_total_earned_premium,
  coalesce(p.amt_total_written_premium, 0)  as amt_total_written_premium,
  case when coalesce(p.amt_total_earned_premium,0)=0 then null
       else round(c.amt_total_claims / p.amt_total_earned_premium, 4) end as claim_ratio
from {{ ref('dim_products') }} prd
left join claims c using (idd_prd_product)
left join prem   p using (idd_prd_product)