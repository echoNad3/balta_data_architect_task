{% set as_of_date = var('as_of_date', run_started_at.strftime('%Y-%m-%d')) %}

with base as (
  select * from {{ ref('stg_customers') }}
),
calc as (
  select
    idd_cus_customer,
    first_name, last_name, gender, city, segment, d_created, country, d_birth_date,
    date_diff('year', d_birth_date, cast('{{ as_of_date }}' as date)) as age_years,
    case
      when d_birth_date is null then 'Unknown'
      when date_diff('year', d_birth_date, cast('{{ as_of_date }}' as date)) < 18 then '00-17'
      when date_diff('year', d_birth_date, cast('{{ as_of_date }}' as date)) < 25 then '18-24'
      when date_diff('year', d_birth_date, cast('{{ as_of_date }}' as date)) < 35 then '25-34'
      when date_diff('year', d_birth_date, cast('{{ as_of_date }}' as date)) < 45 then '35-44'
      when date_diff('year', d_birth_date, cast('{{ as_of_date }}' as date)) < 55 then '45-54'
      when date_diff('year', d_birth_date, cast('{{ as_of_date }}' as date)) < 65 then '55-64'
      else '65+'
    end as age_group
  from base
)
select * from calc