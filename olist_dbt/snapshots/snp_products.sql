{% snapshot snp_products %}

{{
    config(
        target_schema='SILVER_SCHEMA',
        unique_key='product_id',
        strategy='check',
        check_cols=['product_category_name_english', 'product_weight_g', 'product_length_cm']
    )
}}

SELECT
    product_id,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    _loaded_at
FROM {{ ref('stg_products') }}

{% endsnapshot %}