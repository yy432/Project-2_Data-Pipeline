with source as (
    select * from {{ source('olist_raw', 'customers') }}
),
deduped as (
    select
        json_value(data, '$.customer_id')                          as customer_id,
        json_value(data, '$.customer_unique_id')                   as customer_unique_id,
        json_value(data, '$.customer_zip_code_prefix')             as zip_code_prefix,
        initcap(trim(json_value(data, '$.customer_city')))         as customer_city,
        upper(trim(json_value(data, '$.customer_state')))          as customer_state,
        _sdc_received_at
    from source
    qualify row_number() over (
        partition by json_value(data, '$.customer_id')
        order by _sdc_received_at desc
    ) = 1
)
select * except(_sdc_received_at) from deduped
