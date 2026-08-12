SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.price) AS total_sales,
    COUNT(*) AS items_sold
FROM {{ ref('fct_order_items') }} AS f
JOIN {{ ref('dim_date') }} AS d
    ON f.order_date = d.date_day
WHERE f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month