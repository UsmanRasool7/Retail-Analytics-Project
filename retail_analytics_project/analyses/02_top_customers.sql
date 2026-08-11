SELECT
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(*) AS items_purchased,
    SUM(f.price) AS total_spent
FROM {{ ref('fct_order_items') }} AS f
JOIN {{ ref('dim_customers') }} AS c
    ON f.customer_id = c.customer_id
WHERE f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY
    c.customer_unique_id,
    c.customer_city,
    c.customer_state
ORDER BY total_spent DESC