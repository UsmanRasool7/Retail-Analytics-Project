SELECT
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,

    CAST(
        FORMAT_DATE('%Y%m%d', DATE(o.order_purchase_at))
        AS INT64
    ) AS date_key,

    o.order_status,
    oi.price,
    oi.freight_value

FROM {{ ref('stg_order_items') }} AS oi

LEFT JOIN {{ ref('stg_orders') }} AS o
    ON oi.order_id = o.order_id