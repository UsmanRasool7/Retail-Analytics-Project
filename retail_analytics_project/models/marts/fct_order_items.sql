{{ config(
    materialized='incremental',
    unique_key=['order_id', 'order_item_id'],
    incremental_strategy='merge',
    partition_by={
        "field": "order_date",
        "data_type": "date",
        "granularity": "day"
    },
    cluster_by=["product_id", "seller_id"]
) }}

WITH orders AS (

    SELECT
        order_id,
        customer_id,
        order_purchase_ts,
        order_status

    FROM {{ ref('stg_orders') }}

),

order_items AS (

    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        price,
        freight_value

    FROM {{ ref('stg_order_items') }}

),

joined AS (

    SELECT
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        o.customer_id,
        o.order_purchase_ts,
        DATE(o.order_purchase_ts) AS order_date,
        o.order_status,
        oi.price,
        oi.freight_value

    FROM order_items AS oi

    LEFT JOIN orders AS o
        ON oi.order_id = o.order_id

    {% if is_incremental() %}

    WHERE o.order_purchase_ts >= TIMESTAMP_SUB(
        (SELECT MAX(order_purchase_ts) FROM {{ this }}),
        INTERVAL 7 DAY
    )

    {% endif %}

)

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    customer_id,
    order_purchase_ts,
    order_date,
    order_status,
    price,
    freight_value

FROM joined