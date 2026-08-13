{{ config(materialized='table') }}

WITH date_spine AS (

    SELECT
        date_day

    FROM UNNEST(
        GENERATE_DATE_ARRAY(
            DATE('2016-01-01'),
            DATE('2018-12-31'),
            INTERVAL 1 DAY
        )
    ) AS date_day

),

date_attributes AS (

    SELECT
        date_day,
        EXTRACT(YEAR FROM date_day) AS year,
        EXTRACT(QUARTER FROM date_day) AS quarter,
        EXTRACT(MONTH FROM date_day) AS month,
        EXTRACT(DAY FROM date_day) AS day,
        FORMAT_DATE('%B', date_day) AS month_name,
        FORMAT_DATE('%A', date_day) AS day_name,
        EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week

    FROM date_spine

)

SELECT
    date_day,
    year,
    quarter,
    month,
    day,
    month_name,
    day_name,
    day_of_week

FROM date_attributes