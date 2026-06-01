-- models/staging/stg_products.sql

with products as (
    select * from {{ source('olist_raw', 'products') }}
),

translations as (
    select * from {{ source('olist_raw', 'product_category_name_translation') }}
),

joined as (
    select
        p.product_id,
        coalesce(t.product_category_name_english, p.product_category_name, 'unknown') as product_category,
        p.product_category_name                                                         as product_category_pt,
        cast(p.product_name_lenght        as int64)   as product_name_length,
        cast(p.product_description_lenght as int64)   as product_description_length,
        cast(p.product_photos_qty         as int64)   as product_photos_qty,
        cast(p.product_weight_g           as float64) as product_weight_g,
        cast(p.product_length_cm          as float64) as product_length_cm,
        cast(p.product_height_cm          as float64) as product_height_cm,
        cast(p.product_width_cm           as float64) as product_width_cm,

        -- Computed volume (cm³)
        round(
            cast(p.product_length_cm as float64)
          * cast(p.product_height_cm as float64)
          * cast(p.product_width_cm  as float64),
        2) as product_volume_cm3,

        p._sdc_received_at as _loaded_at
    from products p
    left join translations t using (product_category_name)
)

select * from joined
