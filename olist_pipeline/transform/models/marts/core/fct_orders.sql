-- models/marts/core/fct_orders.sql
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  FCT_ORDERS  –  Central fact table (star schema)                        │
-- │  Grain: one row per order                                               │
-- │                                                                         │
-- │  Dimension keys:                                                        │
-- │    customer_key   → dim_customers.customer_key                          │
-- │    date_key       → dim_date.date_key  (order purchase date)            │
-- │                                                                         │
-- │  Degenerate dimensions (stored on fact):                                │
-- │    order_status, primary_payment_type                                   │
-- └─────────────────────────────────────────────────────────────────────────┘

with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select customer_id, customer_unique_id from {{ ref('stg_customers') }}
),

items_summary as (
    select * from {{ ref('int_order_items_summary') }}
),

payments as (
    select * from {{ ref('int_order_payments_pivoted') }}
),

reviews as (
    select * from {{ ref('int_order_reviews_summary') }}
),

final as (
    select
        -- ── Surrogate / natural keys ──────────────────────────────────
        o.order_id,
        c.customer_unique_id                            as customer_key,
        cast(o.order_purchased_at as date)              as date_key,

        -- ── Order attributes (degenerate dims) ───────────────────────
        o.order_status,
        o.is_delivered,
        o.is_canceled,

        -- ── Timestamps ───────────────────────────────────────────────
        o.order_purchased_at,
        o.order_approved_at,
        o.order_shipped_at,
        o.order_delivered_at,
        o.order_estimated_delivery_at,

        -- ── Delivery metrics ─────────────────────────────────────────
        o.actual_delivery_days,
        o.delivery_buffer_days,
        case
            when o.delivery_buffer_days >= 0 then 'on_time_or_early'
            when o.delivery_buffer_days <  0 then 'late'
            else null
        end as delivery_status,

        -- ── Item metrics ─────────────────────────────────────────────
        coalesce(i.item_count,          0)              as item_count,
        coalesce(i.distinct_products,   0)              as distinct_products,
        coalesce(i.distinct_sellers,    0)              as distinct_sellers,
        coalesce(i.items_subtotal,      0)              as items_subtotal,
        coalesce(i.freight_total,       0)              as freight_total,
        coalesce(i.order_gross_total,   0)              as order_gross_total,
        i.avg_item_price,
        i.min_item_price,
        i.max_item_price,

        -- ── Payment metrics ──────────────────────────────────────────
        coalesce(p.total_payment_value, 0)              as total_payment_value,
        p.payment_count,
        p.max_installments,
        p.primary_payment_type,
        p.has_credit_card,
        p.has_boleto,
        p.has_voucher,
        p.has_debit_card,

        -- ── Review metrics ───────────────────────────────────────────
        r.review_id,
        r.review_score,
        r.sentiment                                     as review_sentiment,
        r.has_comment                                   as review_has_comment,
        r.review_created_at,

        -- ── Margin proxy (payment - freight) ─────────────────────────
        round(
            coalesce(p.total_payment_value, 0)
          - coalesce(i.freight_total,       0),
        2) as net_revenue_proxy

    from orders o
    left join customers      c using (customer_id)
    left join items_summary  i using (order_id)
    left join payments       p using (order_id)
    left join reviews        r using (order_id)
)

select * from final
