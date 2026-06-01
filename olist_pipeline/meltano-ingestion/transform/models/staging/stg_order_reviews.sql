with source as (
    select * from {{ source('olist_raw', 'order_reviews') }}
)
select
    json_value(data, '$.review_id')                                     as review_id,
    json_value(data, '$.order_id')                                      as order_id,
    cast(json_value(data, '$.review_score') as int64)                   as review_score,
    json_value(data, '$.review_comment_title')                          as review_title,
    json_value(data, '$.review_comment_message')                        as review_message,
    cast(json_value(data, '$.review_creation_date') as timestamp)       as review_created_at,
    cast(json_value(data, '$.review_answer_timestamp') as timestamp)    as review_answered_at,
    case
        when cast(json_value(data, '$.review_score') as int64) >= 4 then 'positive'
        when cast(json_value(data, '$.review_score') as int64) =  3 then 'neutral'
        else 'negative'
    end as sentiment
from source
