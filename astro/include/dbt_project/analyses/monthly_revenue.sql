SELECT
    d.year,
    d.month,
    d.month_name,
    ROUND(SUM(f.price), 2) AS revenue,
    COUNT(DISTINCT f.order_id) AS orders
FROM `olist-data-warehouse-504705.dbt_dev.fct_order_items` AS f
JOIN `olist-data-warehouse-504705.dbt_dev.dim_date` AS d
    ON f.date_key = d.date_key
WHERE f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;