with items as (
    select * from {{ ref('stg_order_items') }}
),
orders as (
    select order_id, customer_id, order_status, order_purchased_at, is_delivered
    from {{ ref('stg_orders') }}
),
customers as (
    select customer_id, customer_unique_id from {{ ref('stg_customers') }}
)
select
    i.order_id,
    i.order_item_id,
    i.product_id                            as product_key,
    i.seller_id                             as seller_key,
    c.customer_unique_id                    as customer_key,
    cast(o.order_purchased_at as date)      as date_key,
    o.order_status,
    o.is_delivered,
    i.item_price,
    i.freight_value,
    i.item_total
from items i
join orders    o using (order_id)
join customers c using (customer_id)
