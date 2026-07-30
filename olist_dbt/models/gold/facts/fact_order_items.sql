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
            OR (o.order_purchase_timestamp < dp.dbt_valid_from AND dp.is_current = TRUE)
        )
    LEFT JOIN dim_seller_history ds
        ON oi.seller_id = ds.seller_id
        AND (
            o.order_purchase_timestamp BETWEEN ds.dbt_valid_from AND COALESCE(ds.dbt_valid_to, CURRENT_TIMESTAMP())
            OR (o.order_purchase_timestamp < ds.dbt_valid_from AND ds.is_current = TRUE)
        )
)

SELECT * FROM final