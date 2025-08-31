select
  p.idd_pol_policy,
  p.idd_cus_customer
from {{ ref('stg_policies') }} p
left join {{ ref('stg_customers') }} c
  on c.idd_cus_customer = p.idd_cus_customer
where c.idd_cus_customer is null