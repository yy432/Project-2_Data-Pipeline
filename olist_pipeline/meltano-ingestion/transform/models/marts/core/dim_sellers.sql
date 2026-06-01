with sellers as (
    select * from {{ ref('stg_sellers') }}
),
geo as (
    select * from {{ ref('stg_geolocation') }}
)
select
    s.seller_id    as seller_key,
    s.zip_code_prefix,
    s.seller_city  as city,
    s.seller_state as state,
    g.latitude,
    g.longitude,
    case s.seller_state
        when 'SP' then 'Southeast' when 'RJ' then 'Southeast'
        when 'MG' then 'Southeast' when 'ES' then 'Southeast'
        when 'RS' then 'South'     when 'SC' then 'South' when 'PR' then 'South'
        when 'BA' then 'Northeast' when 'PE' then 'Northeast'
        when 'CE' then 'Northeast' when 'MA' then 'Northeast'
        when 'GO' then 'Central-West' when 'DF' then 'Central-West'
        when 'AM' then 'North'     when 'PA' then 'North'
        else 'Unknown'
    end as region
from sellers s
left join geo g on g.zip_code_prefix = s.zip_code_prefix
