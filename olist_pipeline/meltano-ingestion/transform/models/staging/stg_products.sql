with products as (
    select * from {{ source('olist_raw', 'products') }}
),
translations as (
    select
        json_value(data, '$.product_category_name')         as product_category_name,
        json_value(data, '$.product_category_name_english') as product_category_name_english
    from {{ source('olist_raw', 'product_category_name_translation') }}
)
select
    json_value(p.data, '$.product_id')          as product_id,
    coalesce(t.product_category_name_english,
             json_value(p.data, '$.product_category_name'), 'unknown') as product_category,
    json_value(p.data, '$.product_category_name')                      as product_category_pt,
    cast(json_value(p.data, '$.product_name_lenght')        as int64)   as product_name_length,
    cast(json_value(p.data, '$.product_description_lenght') as int64)   as product_description_length,
    cast(json_value(p.data, '$.product_photos_qty')         as int64)   as product_photos_qty,
    cast(json_value(p.data, '$.product_weight_g')           as float64) as product_weight_g,
    cast(json_value(p.data, '$.product_length_cm')          as float64) as product_length_cm,
    cast(json_value(p.data, '$.product_height_cm')          as float64) as product_height_cm,
    cast(json_value(p.data, '$.product_width_cm')           as float64) as product_width_cm
from products p
left join translations t
    on json_value(p.data, '$.product_category_name') = t.product_category_name
