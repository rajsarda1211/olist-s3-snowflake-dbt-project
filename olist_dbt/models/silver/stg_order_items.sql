{{ config(
    materialized='incremental',
    unique_key=['order_id', 'order_item_id'],
    on_schema_change='append_new_columns'
) }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_order_items') }}
),

cleaned AS (
    SELECT
        order_id,
        TRY_CAST(order_item_id AS INT)                 AS order_item_id,
        product_id,
        seller_id,
        TRY_CAST(shipping_limit_date AS TIMESTAMP_NTZ) AS shipping_limit_date,
        TRY_CAST(price AS DECIMAL(10,2))               AS price,
        TRY_CAST(freight_value AS DECIMAL(10,2))       AS freight_value,
        _source_file,
        _loaded_at,
        _row_hash
    FROM source
    WHERE order_id IS NOT NULL
      AND order_item_id IS NOT NULL
      AND product_id IS NOT NULL
      AND seller_id IS NOT NULL

    {% if is_incremental() %}
        AND _loaded_at > (
            SELECT DATEADD(day, -3, MAX(_loaded_at))
            FROM {{ this }}
        )
    {% endif %}
)

SELECT * FROM cleaned