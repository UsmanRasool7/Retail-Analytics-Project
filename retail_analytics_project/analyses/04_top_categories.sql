SELECT
    p.product_category_name_english AS product_category,
    COUNT(*) AS items_sold,
    SUM(f.price) AS total_sales
FROM {{ ref('fct_order_items') }} AS f
JOIN {{ ref('dim_products') }} AS p
    ON f.product_id = p.product_id
WHERE f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY
    p.product_category_name_english
ORDER BY total_sales DESC