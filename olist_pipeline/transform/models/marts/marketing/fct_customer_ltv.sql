-- models/marts/marketing/fct_customer_ltv.sql
-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  FCT_CUSTOMER_LTV                                                      │
-- │  Grain: one row per customer_unique_id (all-time lifetime stats)       │
-- └────────────────────────────────────────────────────────────────────────┘

with orders as (
    select * from {{ ref('fct_orders') }}
),

customers as (
    select * from {{ ref('dim_customers') }}
),

customer_orders as (
    select
        o.customer_key,
        count(distinct o.order_id)                          as total_orders,
        count(distinct o.date_key)                          as active_order_days,
        round(sum(o.total_payment_value), 2)                as lifetime_revenue,
        round(avg(o.total_payment_value), 2)                as avg_order_value,
        round(max(o.total_payment_value), 2)                as max_order_value,
        round(min(o.total_payment_value), 2)                as min_order_value,
        min(o.order_purchased_at)                           as first_order_at,
        max(o.order_purchased_at)                           as last_order_at,
        date_diff(
            cast(max(o.order_purchased_at) as date),
            cast(min(o.order_purchased_at) as date),
            day
        )                                                   as customer_lifespan_days,
        countif(o.is_delivered)                             as delivered_orders,
        countif(o.is_canceled)                              as canceled_orders,
        round(avg(o.review_score), 2)                       as avg_review_score,
        round(avg(o.actual_delivery_days), 1)               as avg_delivery_days,

        -- RFM components
        date_diff(
            current_date(),
            cast(max(o.order_purchased_at) as date),
            day
        )                                                   as recency_days,
        count(distinct o.order_id)                          as frequency,
        round(sum(o.total_payment_value), 2)                as monetary_value

    from orders o
    group by 1
),

rfm_scored as (
    select
        *,
        -- Simple quintile-based RFM scoring (1=worst, 5=best)
        ntile(5) over (order by recency_days    desc) as recency_score,  -- lower days = higher score
        ntile(5) over (order by frequency       asc)  as frequency_score,
        ntile(5) over (order by monetary_value  asc)  as monetary_score
    from customer_orders
),

final as (
    select
        co.customer_key,
        c.city,
        c.state,
        c.region,
        co.total_orders,
        co.lifetime_revenue,
        co.avg_order_value,
        co.max_order_value,
        co.first_order_at,
        co.last_order_at,
        co.customer_lifespan_days,
        co.delivered_orders,
        co.canceled_orders,
        co.avg_review_score,
        co.avg_delivery_days,
        co.recency_days,
        co.frequency,
        co.monetary_value,
        co.recency_score,
        co.frequency_score,
        co.monetary_score,
        co.recency_score + co.frequency_score + co.monetary_score as rfm_total_score,

        -- Customer segment
        case
            when co.recency_score >= 4
             and co.frequency_score >= 4
             and co.monetary_score  >= 4 then 'Champion'
            when co.recency_score >= 3
             and co.frequency_score >= 3 then 'Loyal Customer'
            when co.recency_score >= 4
             and co.frequency_score <= 2 then 'New Customer'
            when co.recency_score <= 2
             and co.frequency_score >= 3 then 'At Risk'
            when co.recency_score <= 2
             and co.frequency_score <= 2
             and co.monetary_score  >= 3 then 'Hibernating'
            when co.recency_score <= 1 then 'Lost'
            else 'Potential Loyalist'
        end as customer_segment

    from rfm_scored co
    join customers  c on c.customer_key = co.customer_key
)

select * from final
