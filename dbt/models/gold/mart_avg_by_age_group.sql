with pol_cust as (
  select p.idd_pol_policy, c.age_group, p.amt_written_premium
  from {{ ref('fct_policy_premium') }} p
  left join {{ ref('dim_customers') }} c
    on c.idd_cus_customer = p.idd_cus_customer
),
claims as (
  select f.idd_pol_policy, d.age_group, f.amt_claim
  from {{ ref('fact_claims') }} f
  left join {{ ref('dim_customers') }} d
    on d.idd_cus_customer = f.idd_cus_customer
)
select
  coalesce(pc.age_group, cl.age_group) as age_group,
  avg(pc.amt_written_premium)          as avg_premium_per_policy,
  avg(cl.amt_claim)                    as avg_claim_per_claim
from pol_cust pc
full outer join claims cl
  on cl.idd_pol_policy = pc.idd_pol_policy
group by 1
order by 1