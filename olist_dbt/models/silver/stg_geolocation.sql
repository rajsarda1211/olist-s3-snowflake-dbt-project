WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_geolocation') }}
),

cleaned AS (
    SELECT
        geolocation_zip_code_prefix,
        TRY_CAST(geolocation_lat AS FLOAT) AS geolocation_lat,
        TRY_CAST(geolocation_lng AS FLOAT) AS geolocation_lng,
        {{ clean_string('geolocation_city') }}  AS geolocation_city,
        {{ clean_string('geolocation_state') }} AS geolocation_state,
        _source_file,
        _loaded_at,
        _row_hash
    FROM source
    WHERE geolocation_zip_code_prefix IS NOT NULL
),

deduplicated AS (
    SELECT
        geolocation_zip_code_prefix,
        AVG(geolocation_lat) AS geolocation_lat,
        AVG(geolocation_lng) AS geolocation_lng,
        MAX(geolocation_city)  AS geolocation_city,
        MAX(geolocation_state) AS geolocation_state,
        MAX(_source_file)      AS _source_file,
        MAX(_loaded_at)        AS _loaded_at,
        MAX(_row_hash)         AS _row_hash
    FROM cleaned
    GROUP BY geolocation_zip_code_prefix
)

SELECT * FROM deduplicated