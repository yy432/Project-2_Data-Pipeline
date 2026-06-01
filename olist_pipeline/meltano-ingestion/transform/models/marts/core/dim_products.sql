with products as (
    select * from {{ ref('stg_products') }}
)
select
    product_id       as product_key,
    product_category as category_english,
    product_category_pt,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_photos_qty,
    case
        when product_weight_g < 500   then 'light'
        when product_weight_g < 5000  then 'medium'
        when product_weight_g < 20000 then 'heavy'
        else 'very_heavy'
    end as weight_tier
from products
