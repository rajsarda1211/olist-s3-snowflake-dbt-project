{% snapshot snp_customers %}

{{
    config(
        target_schema='SILVER_SCHEMA',
        unique_key='customer_unique_id',
        strategy='check',
        check_cols=['customer_city', 'customer_state', 'customer_zip_code_prefix']
    )
}}

WITH deduplicated AS (
    SELECT
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        _loaded_at
    FROM {{ ref('stg_customers') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_unique_id
        ORDER BY _loaded_at DESC
    ) = 1
)

SELECT * FROM deduplicated

{% endsnapshot %}