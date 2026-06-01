-- models/marts/core/dim_products.sql
-- ┌──────────────────────────────────────────────────────────────────┐
-- │  DIM_PRODUCTS  –  Product dimension                              │
-- │  Grain: one row per product_id                                   │
-- └──────────────────────────────────────────────────────────────────┘

with products as (
    select * from {{ ref('stg_products') }}
),

-- Size bucketing thresholds (weight in grams)
final as (
    select
        product_id                    as product_key,
        product_category              as category_english,
        product_category_pt           as category_portuguese,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        product_volume_cm3,

        -- Weight tier
        case
            when product_weight_g < 500   then 'light'
            when product_weight_g < 5000  then 'medium'
            when product_weight_g < 20000 then 'heavy'
            else 'very_heavy'
        end as weight_tier,

        -- Volume tier
        case
            when product_volume_cm3 < 500    then 'small'
            when product_volume_cm3 < 5000   then 'medium'
            when product_volume_cm3 < 50000  then 'large'
            else 'very_large'
        end as volume_tier

    from products
)

select * from final
