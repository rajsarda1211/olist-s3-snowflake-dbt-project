-- Compares distinct entity count, not row count, since dim_customer is SCD2 versioned
WITH silver AS (
    SELECT COUNT(DISTINCT customer_unique_id) AS cnt FROM {{ ref('stg_customers') }}
),
gold AS (
    SELECT COUNT(DISTINCT customer_unique_id) AS cnt FROM {{ ref('dim_customer') }}
)
SELECT silver.cnt AS silver_count, gold.cnt AS gold_count
FROM silver, gold
WHERE silver.cnt != gold.cnt
