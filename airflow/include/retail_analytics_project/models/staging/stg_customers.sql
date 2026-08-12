{{ config(materialized='view') }}

SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    INITCAP(TRIM(customer_city)) AS customer_city,
    UPPER(TRIM(customer_state)) AS customer_state

FROM {{ source('raw', 'olist_customers_dataset') }}