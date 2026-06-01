-- models/marts/core/dim_date.sql
-- ┌──────────────────────────────────────────────────────────────────┐
-- │  DIM_DATE  –  Calendar dimension                                 │
-- │  Grain: one row per calendar date (2016-01-01 → 2022-12-31)     │
-- └──────────────────────────────────────────────────────────────────┘

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart   = "day",
        start_date = "cast('2016-01-01' as date)",
        end_date   = "cast('2023-01-01' as date)"
    ) }}
),

final as (
    select
        cast(date_day as date)                          as date_key,
        cast(date_day as date)                          as full_date,
        extract(year        from date_day)              as year,
        extract(quarter     from date_day)              as quarter,
        extract(month       from date_day)              as month,
        extract(week        from date_day)              as week_of_year,
        extract(dayofyear   from date_day)              as day_of_year,
        extract(day         from date_day)              as day_of_month,
        extract(dayofweek   from date_day)              as day_of_week,   -- 1=Sun … 7=Sat (BQ)

        format_date('%B',      date_day)                as month_name,
        format_date('%b',      date_day)                as month_name_short,
        format_date('%A',      date_day)                as day_name,
        format_date('%a',      date_day)                as day_name_short,
        format_date('%Y-%m',   date_day)                as year_month,
        format_date('%Y-Q%Q',  date_day)                as year_quarter,

        -- Flags
        case when extract(dayofweek from date_day) in (1, 7)
             then true else false end                   as is_weekend,
        case when extract(dayofweek from date_day) not in (1, 7)
             then true else false end                   as is_weekday,

        -- Relative flags (useful for BI filters)
        date_day = current_date()                       as is_today,
        date_day = date_sub(current_date(), interval 1 day) as is_yesterday,
        date_trunc(date_day, month) = date_trunc(current_date(), month) as is_current_month,
        date_trunc(date_day, year)  = date_trunc(current_date(), year)  as is_current_year

    from date_spine
)

select * from final
