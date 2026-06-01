with customers as (
    select * from {{ ref('stg_customers') }}
),
geo as (
    select * from {{ ref('stg_geolocation') }}
)
select
    c.customer_unique_id  as customer_key,
    c.zip_code_prefix,
    c.customer_city       as city,
    c.customer_state      as state,
    g.latitude,
    g.longitude,
    case c.customer_state
        when 'SP' then 'Southeast' when 'RJ' then 'Southeast'
        when 'MG' then 'Southeast' when 'ES' then 'Southeast'
        when 'RS' then 'South'     when 'SC' then 'South' when 'PR' then 'South'
        when 'BA' then 'Northeast' when 'PE' then 'Northeast'
        when 'CE' then 'Northeast' when 'MA' then 'Northeast'
        when 'GO' then 'Central-West' when 'DF' then 'Central-West'
        when 'AM' then 'North'     when 'PA' then 'North'
        else 'Unknown'
    end as region
from customers c
left join geo g on g.zip_code_prefix = c.zip_code_prefix
qualify row_number() over (partition by c.customer_unique_id order by c.customer_id) = 1
