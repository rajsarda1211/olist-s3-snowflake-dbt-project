{{ config(
    unique_key='seller_id'
) }}

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

    {% if is_incremental() %}
        AND _loaded_at > (
            SELECT DATEADD(day, -3, MAX(_loaded_at))
            FROM {{ this }}
        )
    {% endif %}
),

deduplicated AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY seller_id
        ORDER BY _loaded_at DESC
    ) = 1
)

SELECT * FROM deduplicated