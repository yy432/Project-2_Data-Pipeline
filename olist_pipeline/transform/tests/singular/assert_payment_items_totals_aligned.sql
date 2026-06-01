-- tests/singular/assert_payment_items_totals_aligned.sql
-- Payment value should be within 5% of the items gross total for delivered orders.
-- Larger gaps indicate data quality issues in source.

select
    order_id,
    order_gross_total,
    total_payment_value,
    round(abs(total_payment_value - order_gross_total) / nullif(order_gross_total, 0), 4) as discrepancy_pct
from {{ ref('fct_orders') }}
where is_delivered = true
  and order_gross_total > 0
  and total_payment_value > 0
  and abs(total_payment_value - order_gross_total) / order_gross_total > 0.05
