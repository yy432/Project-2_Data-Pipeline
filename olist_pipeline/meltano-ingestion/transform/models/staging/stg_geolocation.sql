with source as (
    select * from {{ source('olist_raw', 'geolocation') }}
)
select
    json_value(data, '$.geolocation_zip_code_prefix')               as zip_code_prefix,
    round(avg(cast(json_value(data, '$.geolocation_lat') as float64)), 6) as latitude,
    round(avg(cast(json_value(data, '$.geolocation_lng') as float64)), 6) as longitude,
    any_value(json_value(data, '$.geolocation_city'))               as city,
    any_value(json_value(data, '$.geolocation_state'))              as state
from source
group by 1
