with src as (select * from {{ ref('offers') }})
select
  offer_id,
  customer_id                                      as idd_cus_customer,
  product_code, product_variant,
  cast(offer_datetime as timestamp)                as dt_offer,
  cast(premium_offered as decimal(18,2))           as amt_premium_offered,
  sales_source,
  cast(sum_insured as decimal(18,2))               as amt_sum_insured,
  coverage_hash
from src