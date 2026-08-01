-- Compares distinct entity count, not row count, since dim_seller is SCD2 versioned
WITH silver AS (
    SELECT COUNT(DISTINCT seller_id) AS cnt FROM {{ ref('stg_sellers') }}
),
gold AS (
    SELECT COUNT(DISTINCT seller_id) AS cnt FROM {{ ref('dim_seller') }}
)
SELECT silver.cnt AS silver_count, gold.cnt AS gold_count
FROM silver, gold
WHERE silver.cnt != gold.cnt
