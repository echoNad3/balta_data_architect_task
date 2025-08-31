-- FAIL customers with impossible/missing dates or crazy ages
with c as (
  select
    idd_cus_customer,
    d_birth_date,
    d_created,
    date_diff('year', d_birth_date, current_date) as age_years
  from {{ ref('stg_customers') }}
)
select *
from c
where d_birth_date is null           -- missing birth date
   or age_years < 0                  -- born in the future
   or age_years > 120                -- unlikely age
   or (d_created is not null and d_birth_date is not null and d_created < d_birth_date) -- account created before birth
