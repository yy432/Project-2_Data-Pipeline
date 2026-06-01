-- models/staging/stg_customers.sql
-- Lightly cleans the raw customers table.
-- customer_id is a session key; customer_unique_id is the true customer.

with source as (
    select * from {{ source('olist_raw', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_unique_id,
        cast(customer_zip_code_prefix as string)  as zip_code_prefix,
        initcap(trim(customer_city))              as customer_city,
        upper(trim(customer_state))               as customer_state,
        _sdc_received_at                          as _loaded_at
    from source
)

select * from renamed
