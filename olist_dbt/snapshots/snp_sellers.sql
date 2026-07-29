{% snapshot snp_sellers %}

{{
    config(
        target_schema='SILVER_SCHEMA',
        unique_key='seller_id',
        strategy='check',
        check_cols=['seller_city', 'seller_state', 'seller_zip_code_prefix']
    )
}}

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    _loaded_at
FROM {{ ref('stg_sellers') }}

{% endsnapshot %}