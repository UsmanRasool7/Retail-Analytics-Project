{{ config(materialized='view') }}

SELECT
    review_id,
    order_id,
    SAFE_CAST(review_score AS INT64) AS review_score,
    NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
    NULLIF(TRIM(review_comment_message), '') AS review_comment_message,

    SAFE_CAST(NULLIF(review_creation_date, '') AS TIMESTAMP) AS review_creation_ts,
    SAFE_CAST(NULLIF(review_answer_timestamp, '') AS TIMESTAMP) AS review_answer_ts

FROM {{ source('raw', 'olist_order_reviews_dataset') }}