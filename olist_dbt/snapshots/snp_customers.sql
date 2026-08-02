{% snapshot snp_customers %}

{{
    config(
        target_schema='SILVER_SCHEMA',
        unique_key='customer_unique_id',
        strategy='check',
        check_cols=['customer_city', 'customer_state', 'customer_zip_code_prefix']
    )
}}

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        c._loaded_at,
        o.order_purchase_timestamp
    FROM {{ ref('stg_customers') }} c
    JOIN {{ ref('stg_orders') }} o
        ON c.customer_id = o.customer_id
),

deduplicated AS (
    SELECT
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        _loaded_at
    FROM customer_orders
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_purchase_timestamp DESC
    ) = 1
)

SELECT * FROM deduplicated

{% endsnapshot %}