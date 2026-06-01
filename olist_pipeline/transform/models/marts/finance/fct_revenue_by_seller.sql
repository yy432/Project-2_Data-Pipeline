-- models/marts/finance/fct_revenue_by_seller.sql
-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  FCT_REVENUE_BY_SELLER                                                 │
-- │  Grain: one row per seller × calendar month                            │
-- └────────────────────────────────────────────────────────────────────────┘

with order_items as (
    select * from {{ ref('fct_order_items') }}
),

sellers as (
    select * from {{ ref('dim_sellers') }}
),

products as (
    select product_key, category_english from {{ ref('dim_products') }}
),

dates as (
    select date_key, year, month, year_month from {{ ref('dim_date') }}
),

aggregated as (
    select
        oi.seller_key,
        d.year,
        d.month,
        d.year_month,
        p.category_english                           as product_category,
        s.state                                      as seller_state,
        s.region                                     as seller_region,

        count(distinct oi.order_id)                  as order_count,
        count(*)                                     as item_count,
        round(sum(oi.item_price),    2)              as gross_revenue,
        round(sum(oi.freight_value), 2)              as freight_revenue,
        round(sum(oi.item_total),    2)              as total_revenue,
        round(avg(oi.item_price),    2)              as avg_selling_price,
        count(distinct oi.customer_key)              as unique_customers

    from order_items oi
    join sellers  s on s.seller_key   = oi.seller_key
    join products p on p.product_key  = oi.product_key
    join dates    d on d.date_key     = oi.date_key
    where oi.is_delivered = true
    group by 1, 2, 3, 4, 5, 6, 7
)

select * from aggregated
