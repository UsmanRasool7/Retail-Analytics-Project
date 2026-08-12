WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_category_name_english,
        COUNT(*) AS order_items_sold,
        COUNT(DISTINCT f.order_id) AS unique_orders,
        SUM(f.price) AS total_sales,
        AVG(f.price) AS avg_item_price
    FROM {{ ref('fct_order_items') }} AS f
    JOIN {{ ref('dim_products') }} AS p
        ON f.product_id = p.product_id
    WHERE f.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY
        p.product_id,
        p.product_category_name_english
)

SELECT
    product_id,
    product_category_name_english,
    order_items_sold,
    unique_orders,
    avg_item_price,
    total_sales,
    total_sales / SUM(total_sales) OVER () * 100 AS sales_share_pct
FROM product_sales
QUALIFY ROW_NUMBER() OVER (ORDER BY total_sales DESC) <= 10
ORDER BY total_sales DESC