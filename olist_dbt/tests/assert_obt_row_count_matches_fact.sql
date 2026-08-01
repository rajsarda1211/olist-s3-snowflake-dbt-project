WITH fact_count AS (
    SELECT COUNT(*) AS cnt FROM {{ ref('fact_order_items') }}
),
obt_count AS (
    SELECT COUNT(*) AS cnt FROM {{ ref('obt_orders') }}
)
SELECT fact_count.cnt AS fact_row_count, obt_count.cnt AS obt_row_count
FROM fact_count, obt_count
WHERE fact_count.cnt != obt_count.cnt
