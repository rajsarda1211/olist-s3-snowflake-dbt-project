WITH silver AS (
    SELECT COUNT(*) AS cnt FROM {{ ref('stg_order_items') }}
),
fact AS (
    SELECT COUNT(*) AS cnt FROM {{ ref('fact_order_items') }}
)
SELECT silver.cnt AS silver_count, fact.cnt AS fact_count
FROM silver, fact
WHERE silver.cnt != fact.cnt
