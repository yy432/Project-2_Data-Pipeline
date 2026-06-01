-- models/staging/stg_order_reviews.sql

with source as (
    select * from {{ source('olist_raw', 'order_reviews') }}
),

renamed as (
    select
        review_id,
        order_id,
        cast(review_score as int64)              as review_score,
        nullif(trim(cast(review_comment_title   as string)), '') as review_title,
        nullif(trim(cast(review_comment_message as string)), '') as review_message,
        cast(review_creation_date    as timestamp) as review_created_at,
        cast(review_answer_timestamp as timestamp) as review_answered_at,

        -- Sentiment bucketing
        case
            when cast(review_score as int64) >= 4 then 'positive'
            when cast(review_score as int64) =  3 then 'neutral'
            else 'negative'
        end as sentiment,

        _sdc_received_at as _loaded_at
    from source
)

select * from renamed
