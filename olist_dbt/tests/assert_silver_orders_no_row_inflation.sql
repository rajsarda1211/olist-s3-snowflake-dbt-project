WITH bronze AS (
    SELECT COUNT(*) AS cnt FROM {{ source('bronze', 'raw_orders') }}
),
silver AS (
    SELECT COUNT(*) AS cnt FROM {{ ref('stg_orders') }}
)
SELECT bronze.cnt AS bronze_count, silver.cnt AS silver_count
FROM bronze, silver
WHERE silver.cnt > bronze.cnt
