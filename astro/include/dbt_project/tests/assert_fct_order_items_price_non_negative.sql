SELECT *
FROM {{ ref('fct_order_items') }}
WHERE price < 0