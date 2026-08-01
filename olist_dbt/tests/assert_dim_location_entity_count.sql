-- dim_location has no SCD2, so row count and entity count are equivalent here
WITH silver AS (
    SELECT COUNT(DISTINCT geolocation_zip_code_prefix) AS cnt FROM {{ ref('stg_geolocation') }}
),
gold AS (
    SELECT COUNT(DISTINCT geolocation_zip_code_prefix) AS cnt FROM {{ ref('dim_location') }}
)
SELECT silver.cnt AS silver_count, gold.cnt AS gold_count
FROM silver, gold
WHERE silver.cnt != gold.cnt
