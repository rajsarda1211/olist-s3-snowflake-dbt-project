WITH source AS (
    SELECT * FROM {{ ref('snp_sellers') }}
),



enriched AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['seller_id', 'dbt_valid_from']) }} AS seller_key,
        seller_id,
        seller_city,
        seller_state,
        seller_zip_code_prefix,
        dbt_valid_from,
        dbt_valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current
    FROM source
)

SELECT * FROM enriched