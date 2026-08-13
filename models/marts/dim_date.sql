WITH order_date_range AS (

    SELECT
        MIN(DATE(order_purchase_at)) AS min_date,
        MAX(DATE(order_purchase_at)) AS max_date

    FROM {{ ref('stg_orders') }}

),

date_spine AS (

    SELECT
        date

    FROM order_date_range,

    UNNEST(
        GENERATE_DATE_ARRAY(
            min_date,
            max_date
        )
    ) AS date

),

date_attributes AS (

    SELECT
        date,
        CAST(FORMAT_DATE('%Y%m%d', date) AS INT64) AS date_key,
        EXTRACT(YEAR FROM date) AS year,
        EXTRACT(QUARTER FROM date) AS quarter,
        EXTRACT(MONTH FROM date) AS month,
        FORMAT_DATE('%B', date) AS month_name,
        EXTRACT(WEEK FROM date) AS week,
        EXTRACT(DAY FROM date) AS day,
        FORMAT_DATE('%A', date) AS day_name

    FROM date_spine

)

SELECT
    date_key,
    date AS full_date,
    year,
    quarter,
    month,
    month_name,
    week,
    day,
    day_name

FROM date_attributes