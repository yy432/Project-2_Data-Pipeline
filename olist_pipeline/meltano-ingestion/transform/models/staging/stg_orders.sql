with source as (
    select * from {{ source('olist_raw', 'orders') }}
),
deduped as (
    select
        json_value(data, '$.order_id')                      as order_id,
        json_value(data, '$.customer_id')                   as customer_id,
        json_value(data, '$.order_status')                  as order_status,
        cast(nullif(json_value(data, '$.order_purchase_timestamp'), '')      as timestamp) as order_purchased_at,
        cast(nullif(json_value(data, '$.order_approved_at'), '')             as timestamp) as order_approved_at,
        cast(nullif(json_value(data, '$.order_delivered_carrier_date'), '')  as timestamp) as order_shipped_at,
        cast(nullif(json_value(data, '$.order_delivered_customer_date'), '') as timestamp) as order_delivered_at,
        cast(nullif(json_value(data, '$.order_estimated_delivery_date'), '') as timestamp) as order_estimated_delivery_at,
        case when json_value(data, '$.order_status') = 'delivered' then true else false end as is_delivered,
        case when json_value(data, '$.order_status') = 'canceled'  then true else false end as is_canceled,
        _sdc_received_at
    from source
    qualify row_number() over (
        partition by json_value(data, '$.order_id')
        order by _sdc_received_at desc
    ) = 1
)
select * except(_sdc_received_at) from deduped
