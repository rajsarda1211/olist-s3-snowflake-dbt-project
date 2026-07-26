WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_products') }}
),

category AS (
    SELECT * FROM {{ source('bronze', 'raw_product_category') }}
),

cleaned AS (
    SELECT
        p.product_id,
        COALESCE(c.product_category_name_english, p.product_category_name, 'uncategorized')  AS product_category_name_english,
        TRY_CAST(p.product_name_lenght AS INT)                      AS product_name_length,
        TRY_CAST(p.product_description_lenght AS INT)               AS product_description_length,
        TRY_CAST(p.product_photos_qty AS INT)                       AS product_photos_qty,
        TRY_CAST(p.product_weight_g AS INT)                         AS product_weight_g,
        TRY_CAST(p.product_length_cm AS INT)                        AS product_length_cm,
        TRY_CAST(p.product_height_cm AS INT)                        AS product_height_cm,
        TRY_CAST(p.product_width_cm AS INT)                         AS product_width_cm,
        p._source_file,
        p._loaded_at,
        p._row_hash
    FROM source p
    LEFT JOIN category c
        ON p.product_category_name = c.product_category_name
    WHERE p.product_id IS NOT NULL
)

SELECT * FROM cleaned