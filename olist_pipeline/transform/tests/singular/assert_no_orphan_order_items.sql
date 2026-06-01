-- tests/singular/assert_no_orphan_order_items.sql
-- Every order_item must have a matching order in stg_orders.

select oi.order_id
from {{ ref('stg_order_items') }} oi
left join {{ ref('stg_orders') }} o using (order_id)
where o.order_id is null
