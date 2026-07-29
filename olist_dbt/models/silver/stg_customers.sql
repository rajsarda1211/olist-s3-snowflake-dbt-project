{{ config(
    unique_key='customer_id'
) }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_customers') }}
),

cleaned AS (
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        {{ clean_string('customer_city') }}  AS customer_city,
        {{ clean_string('customer_state') }} AS customer_state,
        _source_file,
        _loaded_at,
        _row_hash
    FROM source
    WHERE customer_id IS NOT NULL
      AND customer_unique_id IS NOT NULL

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
        PARTITION BY customer_id
        ORDER BY _loaded_at DESC
    ) = 1
)

SELECT * FROM deduplicated