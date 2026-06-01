with source as (
    select * from {{ source('olist_raw', 'order_items') }}
)
select
    json_value(data, '$.order_id')                                  as order_id,
    cast(json_value(data, '$.order_item_id') as int64)              as order_item_id,
    json_value(data, '$.product_id')                                as product_id,
    json_value(data, '$.seller_id')                                 as seller_id,
    cast(json_value(data, '$.shipping_limit_date') as timestamp)    as shipping_limit_at,
    round(cast(json_value(data, '$.price') as float64), 2)          as item_price,
    round(cast(json_value(data, '$.freight_value') as float64), 2)  as freight_value,
    round(cast(json_value(data, '$.price') as float64) + cast(json_value(data, '$.freight_value') as float64), 2) as item_total
from source
