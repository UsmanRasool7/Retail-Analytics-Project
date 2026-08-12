{{ config(materialized='view') }}

SELECT
    seller_id,
    seller_zip_code_prefix,
    INITCAP(TRIM(seller_city)) AS seller_city,
    UPPER(TRIM(seller_state)) AS seller_state

FROM {{ source('raw', 'olist_sellers_dataset') }}