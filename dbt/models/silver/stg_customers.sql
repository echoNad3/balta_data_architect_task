with src as (select * from {{ ref('customers') }})
select
  customer_id                                      as idd_cus_customer,
  first_name, last_name,
  cast(birth_date as date)                         as d_birth_date,
  gender, city, segment,
  cast(created_at as date)                         as d_created,
  country
from src