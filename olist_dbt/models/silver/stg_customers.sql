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
)

SELECT * FROM cleaned