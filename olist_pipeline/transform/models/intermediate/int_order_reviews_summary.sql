-- models/intermediate/int_order_reviews_summary.sql
-- One row per order (takes the latest review if multiple exist).

with reviews as (
    select * from {{ ref('stg_order_reviews') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by order_id
            order by review_created_at desc
        ) as rn
    from reviews
),

latest as (
    select
        order_id,
        review_id,
        review_score,
        review_title,
        review_message,
        review_created_at,
        review_answered_at,
        sentiment,
        case when review_message is not null then true else false end as has_comment
    from ranked
    where rn = 1
)

select * from latest
