{{ config(materialized='view') }}

SELECT
    product_id,
    NULLIF(TRIM(product_category_name), '') AS product_category_name,
    product_name_lenght AS product_name_length,
    product_description_lenght AS product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm

FROM {{ source('raw', 'olist_products_dataset') }}