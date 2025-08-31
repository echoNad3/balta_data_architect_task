with c as (select * from {{ ref('stg_claims') }}),
p as (select * from {{ ref('stg_policies') }}),
d as (select * from {{ ref('dim_products') }})
select
  c.claim_id,
  c.idd_pol_policy,
  p.idd_cus_customer,
  d.idd_prd_product,
  c.d_claim_date,
  c.amt_claim
from c
left join p on p.idd_pol_policy = c.idd_pol_policy
left join d on d.product_code = p.product_code and d.product_variant = p.product_variant