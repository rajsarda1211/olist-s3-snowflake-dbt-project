WITH silver AS (
    SELECT
        SUM(price) AS total_price,
        SUM(freight_value) AS total_freight
    FROM {{ ref('stg_order_items') }}
),
gold AS (
    SELECT
        SUM(price) AS total_price,
        SUM(freight_value) AS total_freight
    FROM {{ ref('fact_order_items') }}
)
SELECT
    silver.total_price AS silver_price,
    gold.total_price   AS gold_price,
    silver.total_freight AS silver_freight,
    gold.total_freight   AS gold_freight
FROM silver, gold
WHERE silver.total_price != gold.total_price
   OR silver.total_freight != gold.total_freight
