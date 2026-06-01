-- models/intermediate/int_order_items_summary.sql
-- Rolls order items up to the order level.

with items as (
    select * from {{ ref('stg_order_items') }}
),

aggregated as (
    select
        order_id,
        count(*)                                 as item_count,
        count(distinct product_id)               as distinct_products,
        count(distinct seller_id)                as distinct_sellers,
        round(sum(item_price),    2)             as items_subtotal,
        round(sum(freight_value), 2)             as freight_total,
        round(sum(item_total),    2)             as order_gross_total,
        round(avg(item_price),    2)             as avg_item_price,
        round(min(item_price),    2)             as min_item_price,
        round(max(item_price),    2)             as max_item_price
    from items
    group by 1
)

select * from aggregated
