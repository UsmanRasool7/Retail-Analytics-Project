WITH sellers AS (

    SELECT
        seller_id,
        zip_code_prefix,
        seller_city,
        seller_state

    FROM {{ ref('stg_sellers') }}

)

SELECT
    seller_id,
    zip_code_prefix,
    seller_city,
    seller_state

FROM sellers