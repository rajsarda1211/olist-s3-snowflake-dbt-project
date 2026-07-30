WITH source AS (
    SELECT * FROM {{ ref('stg_geolocation') }}
),

enriched AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['geolocation_zip_code_prefix']) }} AS location_key,
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state,
        geolocation_lat,
        geolocation_lng
    FROM source
)

SELECT * FROM enriched