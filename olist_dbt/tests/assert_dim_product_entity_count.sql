-- Compares distinct entity count, not row count, since dim_product is SCD2 versioned
WITH silver AS (
    SELECT COUNT(DISTINCT product_id) AS cnt FROM {{ ref('stg_products') }}
),
gold AS (
    SELECT COUNT(DISTINCT product_id) AS cnt FROM {{ ref('dim_product') }}
)
SELECT silver.cnt AS silver_count, gold.cnt AS gold_count
FROM silver, gold
WHERE silver.cnt != gold.cnt
