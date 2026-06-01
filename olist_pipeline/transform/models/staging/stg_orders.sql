-- models/staging/stg_orders.sql

with source as (
    select * from {{ source('olist_raw', 'orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        order_status,
        cast(order_purchase_timestamp      as timestamp) as order_purchased_at,
        cast(order_approved_at             as timestamp) as order_approved_at,
        cast(order_delivered_carrier_date  as timestamp) as order_shipped_at,
        cast(order_delivered_customer_date as timestamp) as order_delivered_at,
        cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_at,

        -- Derived flags
        case when order_status = 'delivered' then true else false end as is_delivered,
        case when order_status = 'canceled'  then true else false end as is_canceled,

        -- Delivery time metrics (only meaningful when delivered)
        case
            when order_delivered_customer_date is not null
              and order_purchase_timestamp    is not null
            then timestamp_diff(
                    cast(order_delivered_customer_date as timestamp),
                    cast(order_purchase_timestamp      as timestamp),
                    day)
        end as actual_delivery_days,

        case
            when order_estimated_delivery_date is not null
              and order_delivered_customer_date is not null
            then timestamp_diff(
                    cast(order_estimated_delivery_date as timestamp),
                    cast(order_delivered_customer_date  as timestamp),
                    day)
        end as delivery_buffer_days,   -- positive = early, negative = late

        _sdc_received_at as _loaded_at
    from source
)

select * from renamed
