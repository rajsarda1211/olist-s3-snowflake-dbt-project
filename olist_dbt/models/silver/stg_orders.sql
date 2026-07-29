{{ config(
    unique_key='order_id'
) }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_orders') }}
),

cleaned AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        TRY_CAST(order_purchase_timestamp AS TIMESTAMP_NTZ)      AS order_purchase_timestamp,
        TRY_CAST(order_approved_at AS TIMESTAMP_NTZ)             AS order_approved_at,
        TRY_CAST(order_delivered_carrier_date AS TIMESTAMP_NTZ)  AS order_delivered_carrier_date,
        TRY_CAST(order_delivered_customer_date AS TIMESTAMP_NTZ) AS order_delivered_customer_date,
        TRY_CAST(order_estimated_delivery_date AS TIMESTAMP_NTZ) AS order_estimated_delivery_date,
        _source_file,
        _loaded_at,
        _row_hash
    FROM source
    WHERE order_id IS NOT NULL
      AND customer_id IS NOT NULL

    {% if is_incremental() %}
        AND _loaded_at > (
            SELECT DATEADD(day, -3, MAX(_loaded_at))
            FROM {{ this }}
        )
    {% endif %}
)

SELECT * FROM cleaned