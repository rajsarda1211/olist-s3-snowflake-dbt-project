WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_sellers') }}
),

cleaned AS (
    SELECT
        seller_id,
        seller_zip_code_prefix,
        {{ clean_string('seller_city') }}  AS seller_city,
        {{ clean_string('seller_state') }} AS seller_state,
        _source_file,
        _loaded_at,
        _row_hash
    FROM source
    WHERE seller_id IS NOT NULL
)

SELECT * FROM cleaned