with source as (
    select * from {{ source('olist_raw', 'order_payments') }}
)
select
    json_value(data, '$.order_id')                                      as order_id,
    cast(json_value(data, '$.payment_sequential') as int64)             as payment_sequential,
    json_value(data, '$.payment_type')                                  as payment_type,
    cast(json_value(data, '$.payment_installments') as int64)           as payment_installments,
    round(cast(json_value(data, '$.payment_value') as float64), 2)      as payment_value
from source
