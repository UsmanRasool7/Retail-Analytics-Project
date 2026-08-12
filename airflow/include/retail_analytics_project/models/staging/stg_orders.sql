{{ config(materialized='view') }}

SELECT
    order_id,
    customer_id,
    LOWER(TRIM(order_status)) AS order_status,

    SAFE_CAST(NULLIF(order_purchase_timestamp, '') AS TIMESTAMP) AS order_purchase_ts,
    SAFE_CAST(NULLIF(order_approved_at, '') AS TIMESTAMP) AS order_approved_ts,
    SAFE_CAST(NULLIF(order_delivered_carrier_date, '') AS TIMESTAMP) AS order_delivered_carrier_ts,
    SAFE_CAST(NULLIF(order_delivered_customer_date, '') AS TIMESTAMP) AS order_delivered_customer_ts,
    SAFE_CAST(NULLIF(order_estimated_delivery_date, '') AS TIMESTAMP) AS order_estimated_delivery_ts

FROM {{ source('raw', 'olist_orders_dataset') }}