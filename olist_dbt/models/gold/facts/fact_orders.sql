{{ config(
    unique_key='order_id'
) }}

{% if is_incremental() %}
WITH max_loaded AS (
    SELECT DATEADD(day, -3, MAX(_loaded_at)) AS threshold FROM {{ this }}
),
{% else %}
WITH
{% endif %}

orders AS (
    SELECT o.*
    FROM {{ ref('stg_orders') }} o
    {% if is_incremental() %}
    CROSS JOIN max_loaded
    WHERE o._loaded_at > max_loaded.threshold
    {% endif %}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

dim_customer_history AS (
    SELECT * FROM {{ ref('dim_customer') }}
),

payments_agg AS (
    SELECT
        order_id,
        SUM(payment_value)                    AS total_payment_value,
        LISTAGG(DISTINCT payment_type, ', ')  AS payment_types,
        MAX(payment_installments)             AS max_installments
    FROM {{ ref('stg_order_payments') }}
    GROUP BY order_id
),

reviews_agg AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score,
        COUNT(*)           AS review_count
    FROM {{ ref('stg_order_reviews') }}
    GROUP BY order_id
),

items_agg AS (
    SELECT
        order_id,
        SUM(price)                       AS total_product_price,
        SUM(freight_value)                AS total_freight_value,
        SUM(price) + SUM(freight_value)   AS total_order_value,
        COUNT(*)                          AS total_items_count
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id
),

joined AS (
    -- KNOWN LIMITATION — SCD2 attribution for pre-tracking historical orders:
    -- Real Olist order data spans 2016-2020, but SCD2 snapshot tracking only began when
    -- this project's snapshots were first run (2026). For any order that predates the
    -- earliest snapshot version, this join always resolves to whichever dimension row
    -- is currently marked is_current = TRUE — NOT the customer's true historical state
    -- at the time of that order, since that history was never captured. Orders placed
    -- AFTER real snapshot tracking began correctly reflect true point-in-time state.
    SELECT
        o.order_id,
        dc.customer_key,
        TO_NUMBER(TO_CHAR(o.order_purchase_timestamp, 'YYYYMMDD')) AS date_key,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        p.total_payment_value,
        p.payment_types,
        p.max_installments,
        i.total_product_price,
        i.total_freight_value,
        i.total_order_value,
        i.total_items_count,
        r.avg_review_score,
        r.review_count,
        DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_days,
        CASE
            WHEN o.order_delivered_customer_date IS NULL THEN NULL
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN TRUE
            ELSE FALSE
        END AS is_late_delivery,
        DATEDIFF(day, o.order_purchase_timestamp, o.order_approved_at) AS approval_days,
        o._loaded_at,
        CASE
            WHEN o.order_purchase_timestamp BETWEEN dc.dbt_valid_from AND COALESCE(dc.dbt_valid_to, CURRENT_TIMESTAMP()) THEN 0
            ELSE 1
        END AS join_priority
    FROM orders o
    LEFT JOIN customers c
        ON o.customer_id = c.customer_id
    LEFT JOIN dim_customer_history dc
        ON c.customer_unique_id = dc.customer_unique_id
        AND (
            o.order_purchase_timestamp BETWEEN dc.dbt_valid_from AND COALESCE(dc.dbt_valid_to, CURRENT_TIMESTAMP())
            OR dc.is_current = TRUE
        )
    LEFT JOIN payments_agg p ON o.order_id = p.order_id
    LEFT JOIN reviews_agg r ON o.order_id = r.order_id
    LEFT JOIN items_agg i ON o.order_id = i.order_id
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY o.order_id
        ORDER BY join_priority
    ) = 1
)

SELECT * EXCLUDE join_priority FROM joined