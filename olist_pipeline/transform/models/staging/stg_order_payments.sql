-- models/staging/stg_order_payments.sql

with source as (
    select * from {{ source('olist_raw', 'order_payments') }}
),

renamed as (
    select
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        round(payment_value, 2) as payment_value,
        _sdc_received_at as _loaded_at
    from source
)

select * from renamed
