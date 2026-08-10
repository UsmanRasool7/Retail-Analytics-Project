SELECT
    geolocation_zip_code_prefix AS zip_code_prefix,
    TRIM(LOWER(geolocation_city)) AS city,
    UPPER(geolocation_state) AS state,
    CAST(geolocation_lat AS FLOAT64) AS latitude,
    CAST(geolocation_lng AS FLOAT64) AS longitude

FROM {{ source('raw', 'geolocation') }}