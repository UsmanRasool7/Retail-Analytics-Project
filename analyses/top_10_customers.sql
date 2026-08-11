SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    ROUND(SUM(f.price + f.freight_value), 2) AS total_spent
FROM `olist-data-warehouse-504705.dbt_dev.fct_order_items` AS f
JOIN `olist-data-warehouse-504705.dbt_dev.dim_customers` AS c
    ON f.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state
ORDER BY total_spent DESC
LIMIT 10;