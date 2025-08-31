with src as (
  select * from {{ ref('claims') }}
)
select
  claim_id                                         as claim_id,              -- keep raw id for trace
  policy_id                                        as idd_pol_policy,        -- FK to policy dimension per naming std
  cast(claim_date   as date)                       as d_claim_date,
  cast(claim_amount as decimal(18,2))              as amt_claim
from src