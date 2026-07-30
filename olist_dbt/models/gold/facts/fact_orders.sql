{{ config(
    unique_key='order_id'
) }}

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}

    {% if is_incremental() %}
        WHERE _loaded_at > (
            SELECT DATEADD(day, -3, MAX(_loaded_at))
            FROM {{ this }}
        )
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

final AS (
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
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN TRUE
            ELSE FALSE
        END AS is_late_delivery,
        DATEDIFF(day, o.order_purchase_timestamp, o.order_approved_at) AS approval_days
    FROM orders o
    LEFT JOIN customers c
        ON o.customer_id = c.customer_id
    LEFT JOIN dim_customer_history dc
        ON c.customer_unique_id = dc.customer_unique_id
        AND (
            o.order_purchase_timestamp BETWEEN dc.dbt_valid_from AND COALESCE(dc.dbt_valid_to, CURRENT_TIMESTAMP())
            OR (o.order_purchase_timestamp < dc.dbt_valid_from AND dc.is_current = TRUE)
        )
    LEFT JOIN payments_agg p
        ON o.order_id = p.order_id
    LEFT JOIN reviews_agg r
        ON o.order_id = r.order_id
    LEFT JOIN items_agg i
        ON o.order_id = i.order_id
)

SELECT * FROM final