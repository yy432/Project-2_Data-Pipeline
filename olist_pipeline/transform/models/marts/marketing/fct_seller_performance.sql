-- models/marts/marketing/fct_seller_performance.sql
-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  FCT_SELLER_PERFORMANCE                                                │
-- │  Grain: one row per seller_key (all-time)                              │
-- └────────────────────────────────────────────────────────────────────────┘

with order_items as (
    select * from {{ ref('fct_order_items') }}
),

orders as (
    select order_id, actual_delivery_days, delivery_buffer_days,
           delivery_status, review_score, review_sentiment
    from {{ ref('fct_orders') }}
),

sellers as (
    select * from {{ ref('dim_sellers') }}
),

seller_stats as (
    select
        oi.seller_key,
        count(distinct oi.order_id)                      as total_orders,
        count(*)                                         as total_items_sold,
        count(distinct oi.product_key)                   as distinct_products,
        count(distinct oi.customer_key)                  as unique_customers,
        round(sum(oi.item_price),    2)                  as gross_revenue,
        round(sum(oi.freight_value), 2)                  as freight_charged,
        round(avg(oi.item_price),    2)                  as avg_item_price,
        min(oi.date_key)                                 as first_sale_date,
        max(oi.date_key)                                 as last_sale_date,

        -- Delivery metrics (from fct_orders)
        round(avg(o.actual_delivery_days),  1)           as avg_delivery_days,
        round(avg(o.delivery_buffer_days),  1)           as avg_delivery_buffer,
        countif(o.delivery_status = 'late')              as late_deliveries,
        countif(o.delivery_status = 'on_time_or_early')  as on_time_deliveries,
        round(safe_divide(
            countif(o.delivery_status = 'on_time_or_early'),
            countif(o.delivery_status is not null)
        ) * 100, 2)                                      as on_time_pct,

        -- Review metrics
        round(avg(o.review_score), 2)                    as avg_review_score,
        countif(o.review_sentiment = 'positive')         as positive_reviews,
        countif(o.review_sentiment = 'neutral')          as neutral_reviews,
        countif(o.review_sentiment = 'negative')         as negative_reviews

    from order_items oi
    left join orders o using (order_id)
    where oi.is_delivered = true
    group by 1
),

final as (
    select
        ss.*,
        s.city             as seller_city,
        s.state            as seller_state,
        s.region           as seller_region,

        -- Performance tier
        case
            when ss.avg_review_score >= 4.5 and ss.on_time_pct >= 90 then 'Top Performer'
            when ss.avg_review_score >= 3.5 and ss.on_time_pct >= 75 then 'Good Performer'
            when ss.avg_review_score >= 2.5 or  ss.on_time_pct >= 60 then 'Average Performer'
            else 'Needs Improvement'
        end as performance_tier

    from seller_stats ss
    join sellers      s on s.seller_key = ss.seller_key
)

select * from final
