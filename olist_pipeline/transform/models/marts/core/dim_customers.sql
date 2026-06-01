-- models/marts/core/dim_customers.sql
-- ┌─────────────────────────────────────────────────────────────────────┐
-- │  DIM_CUSTOMERS  –  Star schema customer dimension                   │
-- │  Grain: one row per customer_unique_id                              │
-- └─────────────────────────────────────────────────────────────────────┘

with customers as (
    select * from {{ ref('stg_customers') }}
),

geo as (
    select * from {{ ref('stg_geolocation') }}
),

-- Deduplicate to unique customers and pull their most recent zip/city/state
unique_customers as (
    select
        customer_unique_id,
        -- use the most recent customer_id session record
        array_agg(
            struct(customer_id, zip_code_prefix, customer_city, customer_state)
            order by _loaded_at desc
            limit 1
        )[offset(0)] as latest
    from customers
    group by 1
),

final as (
    select
        uc.customer_unique_id                  as customer_key,
        uc.latest.customer_id                  as latest_session_id,
        uc.latest.zip_code_prefix              as zip_code_prefix,
        uc.latest.customer_city                as city,
        uc.latest.customer_state               as state,
        g.latitude,
        g.longitude,

        -- Brazil region mapping
        case uc.latest.customer_state
            when 'SP' then 'Southeast' when 'RJ' then 'Southeast'
            when 'MG' then 'Southeast' when 'ES' then 'Southeast'
            when 'RS' then 'South'     when 'SC' then 'South'
            when 'PR' then 'South'
            when 'BA' then 'Northeast' when 'PE' then 'Northeast'
            when 'CE' then 'Northeast' when 'MA' then 'Northeast'
            when 'PB' then 'Northeast' when 'RN' then 'Northeast'
            when 'AL' then 'Northeast' when 'SE' then 'Northeast'
            when 'PI' then 'Northeast'
            when 'GO' then 'Central-West' when 'MT' then 'Central-West'
            when 'MS' then 'Central-West' when 'DF' then 'Central-West'
            when 'AM' then 'North'     when 'PA' then 'North'
            when 'RO' then 'North'     when 'AC' then 'North'
            when 'AP' then 'North'     when 'RR' then 'North'
            when 'TO' then 'North'
            else 'Unknown'
        end as region
    from unique_customers uc
    left join geo g on g.zip_code_prefix = uc.latest.zip_code_prefix
)

select * from final
