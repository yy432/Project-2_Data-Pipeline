-- models/marts/core/fct_order_items.sql
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  FCT_ORDER_ITEMS  –  Line-item fact table                               │
-- │  Grain: one row per order_id + order_item_id                            │
-- │                                                                         │
-- │  Dimension keys:                                                        │
-- │    product_key  → dim_products.product_key                              │
-- │    seller_key   → dim_sellers.seller_key                                │
-- │    date_key     → dim_date.date_key  (order purchase date)              │
-- └─────────────────────────────────────────────────────────────────────────┘

with items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select
        order_id,
        customer_id,
        order_status,
        order_purchased_at,
        is_delivered
    from {{ ref('stg_orders') }}
),

customers as (
    select customer_id, customer_unique_id from {{ ref('stg_customers') }}
),

final as (
    select
        -- ── Keys ─────────────────────────────────────────────────────
        i.order_id,
        i.order_item_id,
        i.product_id                            as product_key,
        i.seller_id                             as seller_key,
        c.customer_unique_id                    as customer_key,
        cast(o.order_purchased_at as date)      as date_key,

        -- ── Order context ────────────────────────────────────────────
        o.order_status,
        o.is_delivered,
        o.order_purchased_at,
        i.shipping_limit_at,

        -- ── Financials ───────────────────────────────────────────────
        i.item_price,
        i.freight_value,
        i.item_total,

        -- ── Freight ratio ────────────────────────────────────────────
        case
            when i.item_total > 0
            then round(i.freight_value / i.item_total, 4)
            else null
        end as freight_pct_of_total

    from items      i
    join orders     o using (order_id)
    join customers  c using (customer_id)
)

select * from final
