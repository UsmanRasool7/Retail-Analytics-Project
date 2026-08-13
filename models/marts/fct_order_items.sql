{{ config(
    materialized='incremental',
    unique_key=['order_id', 'order_item_id'],
    incremental_strategy='merge',
    partition_by={
        "field": "order_purchase_at",
        "data_type": "timestamp",
        "granularity": "day"
    },
    cluster_by=['product_id', 'seller_id']
) }}

WITH order_items AS (

    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        price,
        freight_value

    FROM {{ ref('stg_order_items') }}

),

orders AS (

    SELECT
        order_id,
        customer_id,
        order_purchase_at,
        order_status

    FROM {{ ref('stg_orders') }}

),

order_items_joined AS (

    SELECT
        oi.order_id,
        oi.order_item_id,
        o.customer_id,
        oi.product_id,
        oi.seller_id,

        CAST(
            FORMAT_DATE(
                '%Y%m%d',
                DATE(o.order_purchase_at)
            ) AS INT64
        ) AS date_key,

        o.order_purchase_at,
        o.order_status,
        oi.price,
        oi.freight_value

    FROM order_items AS oi

    LEFT JOIN orders AS o
        ON oi.order_id = o.order_id

    {% if is_incremental() %}

    WHERE o.order_purchase_at >= TIMESTAMP_SUB(
        (
            SELECT MAX(order_purchase_at)
            FROM {{ this }}
        ),
        INTERVAL 7 DAY
    )

    {% endif %}

)

SELECT
    order_id,
    order_item_id,
    customer_id,
    product_id,
    seller_id,
    date_key,
    order_purchase_at,
    order_status,
    price,
    freight_value

FROM order_items_joined