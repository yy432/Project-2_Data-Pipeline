-- models/staging/stg_sellers.sql

with source as (
    select * from {{ source('olist_raw', 'sellers') }}
),

renamed as (
    select
        seller_id,
        cast(seller_zip_code_prefix as string) as zip_code_prefix,
        initcap(trim(seller_city))             as seller_city,
        upper(trim(seller_state))              as seller_state,
        _sdc_received_at as _loaded_at
    from source
)

select * from renamed
