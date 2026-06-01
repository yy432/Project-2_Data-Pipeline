-- models/staging/stg_geolocation.sql
-- De-duplicates geolocation by taking the first (median-like) lat/lng per ZIP.

with source as (
    select * from {{ source('olist_raw', 'geolocation') }}
),

deduped as (
    select
        cast(geolocation_zip_code_prefix as string) as zip_code_prefix,
        round(avg(geolocation_lat), 6)              as latitude,
        round(avg(geolocation_lng), 6)              as longitude,
        initcap(trim(
            -- Most frequent city per ZIP
            approx_top_count(geolocation_city,  1)[offset(0)].value
        )) as city,
        upper(trim(
            approx_top_count(geolocation_state, 1)[offset(0)].value
        )) as state
    from source
    group by 1
)

select * from deduped
