with orders as (
    select * from {{ ref('stg_orders') }}
),
customers as (
    select customer_id, customer_unique_id from {{ ref('stg_customers') }}
),
payments as (
    select
        order_id,
        round(sum(payment_value), 2)          as total_payment_value,
        count(distinct payment_sequential)    as payment_count,
        max(payment_installments)             as max_installments,
        any_value(payment_type)               as primary_payment_type
    from {{ ref('stg_order_payments') }}
    group by 1
),
items as (
    select
        order_id,
        count(*)                              as item_count,
        round(sum(item_price), 2)             as items_subtotal,
        round(sum(freight_value), 2)          as freight_total,
        round(sum(item_total), 2)             as order_gross_total
    from {{ ref('stg_order_items') }}
    group by 1
),
reviews as (
    select
        order_id,
        review_score,
        sentiment
    from {{ ref('stg_order_reviews') }}
    qualify row_number() over (partition by order_id order by review_created_at desc) = 1
)
select
    o.order_id,
    c.customer_unique_id                        as customer_key,
    cast(o.order_purchased_at as date)          as date_key,
    o.order_status,
    o.is_delivered,
    o.is_canceled,
    o.order_purchased_at,
    o.order_approved_at,
    o.order_shipped_at,
    o.order_delivered_at,
    o.order_estimated_delivery_at,
    coalesce(i.item_count, 0)                   as item_count,
    coalesce(i.items_subtotal, 0)               as items_subtotal,
    coalesce(i.freight_total, 0)                as freight_total,
    coalesce(i.order_gross_total, 0)            as order_gross_total,
    coalesce(p.total_payment_value, 0)          as total_payment_value,
    p.payment_count,
    p.max_installments,
    p.primary_payment_type,
    r.review_score,
    r.sentiment                                 as review_sentiment
from orders o
left join customers  c using (customer_id)
left join items      i using (order_id)
left join payments   p using (order_id)
left join reviews    r using (order_id)
