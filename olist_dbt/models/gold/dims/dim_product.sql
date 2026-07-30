WITH source AS (
    SELECT * FROM {{ ref('snp_products') }}
),

enriched AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['product_id', 'dbt_valid_from']) }} AS product_key,
        product_id,
        product_category_name_english,
        product_name_length,
        product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        dbt_valid_from,
        dbt_valid_to,
        CASE WHEN dbt_valid_to IS NULL THEN TRUE ELSE FALSE END AS is_current
    FROM source
)

SELECT * FROM enriched