-- models/staging/stg_order_items.sql

with source as (
    select * from {{ source('olist_raw', 'order_items') }}
),

renamed as (
    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        cast(shipping_limit_date as timestamp) as shipping_limit_at,
        round(price,         2) as item_price,
        round(freight_value, 2) as freight_value,
        round(price + freight_value, 2) as item_total,
        _sdc_received_at as _loaded_at
    from source
)

select * from renamed
