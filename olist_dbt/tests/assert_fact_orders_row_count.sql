WITH silver AS (
    SELECT COUNT(*) AS cnt FROM {{ ref('stg_orders') }}
),
gold AS (
    SELECT COUNT(*) AS cnt FROM {{ ref('fact_orders') }}
)
SELECT silver.cnt AS silver_count, gold.cnt AS gold_count
FROM silver, gold
WHERE silver.cnt != gold.cnt
