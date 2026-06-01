-- tests/singular/assert_no_negative_prices.sql
-- All item prices and freight values must be >= 0

select
    order_id,
    order_item_id,
    item_price,
    freight_value
from {{ ref('stg_order_items') }}
where item_price < 0
   or freight_value < 0
