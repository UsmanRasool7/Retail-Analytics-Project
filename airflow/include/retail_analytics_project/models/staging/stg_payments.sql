{{ config(materialized='view') }}

SELECT
    order_id,
    payment_sequential,
    LOWER(TRIM(payment_type)) AS payment_type,
    SAFE_CAST(payment_installments AS INT64) AS payment_installments,
    SAFE_CAST(payment_value AS FLOAT64) AS payment_value

FROM {{ source('raw', 'olist_order_payments_dataset') }}