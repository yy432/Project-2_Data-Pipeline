-- models/intermediate/int_order_payments_pivoted.sql
-- Aggregates multi-row payment records into one row per order.

with payments as (
    select * from {{ ref('stg_order_payments') }}
),

aggregated as (
    select
        order_id,
        round(sum(payment_value), 2)                                   as total_payment_value,
        count(distinct payment_sequential)                             as payment_count,
        max(payment_installments)                                      as max_installments,

        -- Payment type flags
        max(case when payment_type = 'credit_card' then 1 else 0 end) as has_credit_card,
        max(case when payment_type = 'boleto'      then 1 else 0 end) as has_boleto,
        max(case when payment_type = 'voucher'     then 1 else 0 end) as has_voucher,
        max(case when payment_type = 'debit_card'  then 1 else 0 end) as has_debit_card,

        -- Dominant payment type
        approx_top_count(payment_type, 1)[offset(0)].value            as primary_payment_type
    from payments
    group by 1
)

select * from aggregated
