WITH date_range AS (

    SELECT
        MIN(DATE(order_purchase_at)) AS min_date,
        MAX(DATE(order_purchase_at)) AS max_date
    FROM {{ ref('stg_orders') }}

),

dates AS (

    SELECT
        date
    FROM date_range,
    UNNEST(GENERATE_DATE_ARRAY(min_date, max_date)) AS date

)

SELECT
    CAST(FORMAT_DATE('%Y%m%d', date) AS INT64) AS date_key,
    date AS full_date,
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(QUARTER FROM date) AS quarter,
    EXTRACT(MONTH FROM date) AS month,
    FORMAT_DATE('%B', date) AS month_name,
    EXTRACT(WEEK FROM date) AS week,
    EXTRACT(DAY FROM date) AS day,
    FORMAT_DATE('%A', date) AS day_name

FROM dates