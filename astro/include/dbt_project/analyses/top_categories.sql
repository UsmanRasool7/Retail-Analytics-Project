SELECT
    p.product_category_name_english AS category,
    ROUND(SUM(f.price), 2) AS total_revenue,
    COUNT(*) AS items_sold
FROM `olist-data-warehouse-504705.dbt_dev.fct_order_items` AS f
JOIN `olist-data-warehouse-504705.dbt_dev.dim_products` AS p
    ON f.product_id = p.product_id
WHERE f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;