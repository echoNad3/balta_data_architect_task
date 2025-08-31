select
  lower(md5(coalesce(product_code,'')||'|'||coalesce(product_variant,''))) as idd_prd_product,
  product_code,
  product_variant
from {{ ref('stg_policies') }}
group by 1,2,3