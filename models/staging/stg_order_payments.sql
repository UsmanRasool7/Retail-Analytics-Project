SELECT
    CAST(order_id AS STRING) AS order_id,
    CAST(payment_sequential AS INT64) AS payment_sequential,
    TRIM(LOWER(payment_type)) AS payment_type,
    CAST(payment_installments AS INT64) AS payment_installments,
    CAST(payment_value AS NUMERIC) AS payment_value

FROM {{ source('raw', 'order_payments') }}