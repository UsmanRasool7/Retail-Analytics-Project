SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS items_sold,
    SUM(f.price) AS total_sales
FROM {{ ref('fct_order_items') }} AS f
JOIN {{ ref('dim_sellers') }} AS s
    ON f.seller_id = s.seller_id
WHERE f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY total_sales DESC