WITH source AS (
    SELECT * FROM {{ ref('snp_customers') }}
),

enriched AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['customer_unique_id', 'dbt_valid_from']) }} AS customer_key,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        dbt_valid_from,
        dbt_valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current
    FROM source
)

SELECT * FROM enriched