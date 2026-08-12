{{ config(materialized='view') }}

SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    INITCAP(TRIM(geolocation_city)) AS geolocation_city,
    UPPER(TRIM(geolocation_state)) AS geolocation_state

FROM {{ source('raw', 'olist_geolocation_dataset') }}