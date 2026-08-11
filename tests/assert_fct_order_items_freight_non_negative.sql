SELECT *
FROM {{ ref('fct_order_items') }}
WHERE freight_value < 0