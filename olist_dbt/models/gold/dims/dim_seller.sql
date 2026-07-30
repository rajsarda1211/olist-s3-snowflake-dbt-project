WITH source AS (
    SELECT * FROM {{ ref('snp_sellers') }}
),

location AS (
    SELECT * FROM {{ ref('stg_geolocation') }}
),

enriched AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['s.seller_id', 's.dbt_valid_from']) }} AS seller_key,
        s.seller_id,
        s.seller_city,
        s.seller_state,
        s.seller_zip_code_prefix,
        l.geolocation_lat,
        l.geolocation_lng,
        s.dbt_valid_from,
        s.dbt_valid_to,
        CASE WHEN s.dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current
    FROM source s
    LEFT JOIN location l
        ON s.seller_zip_code_prefix = l.geolocation_zip_code_prefix
)

SELECT * FROM enriched