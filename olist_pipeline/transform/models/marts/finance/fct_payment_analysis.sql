-- models/marts/finance/fct_payment_analysis.sql
-- ┌────────────────────────────────────────────────────────────────────────┐
-- │  FCT_PAYMENT_ANALYSIS                                                  │
-- │  Grain: one row per payment_type × calendar month                      │
-- └────────────────────────────────────────────────────────────────────────┘

with payments as (
    select * from {{ ref('stg_order_payments') }}
),

orders as (
    select order_id, order_purchased_at, order_status
    from {{ ref('stg_orders') }}
),

dates as (
    select date_key, year, month, year_month from {{ ref('dim_date') }}
),

joined as (
    select
        p.payment_type,
        p.payment_installments,
        p.payment_value,
        cast(o.order_purchased_at as date) as date_key,
        o.order_status
    from payments p
    join orders o using (order_id)
),

aggregated as (
    select
        j.payment_type,
        d.year,
        d.month,
        d.year_month,
        j.order_status,

        count(*)                                     as payment_record_count,
        count(distinct j.date_key)                   as active_days,
        round(sum(j.payment_value),       2)         as total_payment_value,
        round(avg(j.payment_value),       2)         as avg_payment_value,
        round(avg(j.payment_installments),2)         as avg_installments,
        max(j.payment_installments)                  as max_installments,
        countif(j.payment_installments > 1)          as installment_payment_count,
        round(
            safe_divide(
                countif(j.payment_installments > 1),
                count(*)
            ) * 100, 2
        )                                            as installment_pct

    from joined j
    join dates d on d.date_key = j.date_key
    group by 1, 2, 3, 4, 5
)

select * from aggregated
