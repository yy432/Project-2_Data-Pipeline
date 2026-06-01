with source as (
    select * from {{ source('olist_raw', 'sellers') }}
)
select
    json_value(data, '$.seller_id')                             as seller_id,
    json_value(data, '$.seller_zip_code_prefix')                as zip_code_prefix,
    initcap(trim(json_value(data, '$.seller_city')))            as seller_city,
    upper(trim(json_value(data, '$.seller_state')))             as seller_state
from source
