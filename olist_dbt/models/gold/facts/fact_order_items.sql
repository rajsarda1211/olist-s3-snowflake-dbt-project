{{ config(
    unique_key=['order_id', 'order_item_id']
) }}

WITH order_items AS (
    SELECT * FROM {{ ref('stg_order_items') }}

    {% if is_incremental() %}
        WHERE _loaded_at > (
            SELECT DATEADD(day, -3, MAX(_loaded_at))
            FROM {{ this }}
        )
    {% endif %}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

dim_product_history AS (
    SELECT * FROM {{ ref('dim_product') }}
),

dim_seller_history AS (
    SELECT * FROM {{ ref('dim_seller') }}
),

final AS (
    -- KNOWN LIMITATION — SCD2 attribution for pre-tracking historical orders:
    -- Real Olist order data spans 2016-2020, but SCD2 snapshot tracking only began when
    -- this project's snapshots were first run (2026). For any order that predates the
    -- earliest snapshot version, the NOT EXISTS fallback below will always resolve to
    -- whichever dimension row is currently marked is_current = TRUE — NOT the product/seller's
    -- true historical state at the time of that order, since that history was never captured.
    -- Orders placed AFTER real snapshot tracking began will correctly reflect true
    -- point-in-time state via the ranged BETWEEN match.
    SELECT
        oi.order_id,
        oi.order_item_id,
        dp.product_key,
        ds.seller_key,
        TO_NUMBER(TO_CHAR(o.order_purchase_timestamp, 'YYYYMMDD')) AS date_key,
        oi.shipping_limit_date,
        oi.price,
        oi.freight_value,
        oi.price + oi.freight_value AS total_item_value
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    LEFT JOIN dim_product_history dp
        ON oi.product_id = dp.product_id
        AND (
            o.order_purchase_timestamp BETWEEN dp.dbt_valid_from AND COALESCE(dp.dbt_valid_to, CURRENT_TIMESTAMP())
            OR (
                dp.is_current = TRUE
                AND NOT EXISTS (
                    SELECT 1 FROM dim_product_history dp2
                    WHERE dp2.product_id = dp.product_id
                    AND o.order_purchase_timestamp BETWEEN dp2.dbt_valid_from AND COALESCE(dp2.dbt_valid_to, CURRENT_TIMESTAMP())
                )
            )
        )
    LEFT JOIN dim_seller_history ds
        ON oi.seller_id = ds.seller_id
        AND (
            o.order_purchase_timestamp BETWEEN ds.dbt_valid_from AND COALESCE(ds.dbt_valid_to, CURRENT_TIMESTAMP())
            OR (
                ds.is_current = TRUE
                AND NOT EXISTS (
                    SELECT 1 FROM dim_seller_history ds2
                    WHERE ds2.seller_id = ds.seller_id
                    AND o.order_purchase_timestamp BETWEEN ds2.dbt_valid_from AND COALESCE(ds2.dbt_valid_to, CURRENT_TIMESTAMP())
                )
            )
        )
)

SELECT * FROM final