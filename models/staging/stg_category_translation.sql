SELECT
    product_category_name,
    TRIM(LOWER(product_category_name_english)) AS product_category_name_english

FROM {{ source('raw', 'product_category_translation') }}