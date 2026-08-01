SELECT
    order_id,
    order_item_id,
    product_key,
    seller_key,
    date_key
FROM {{ ref('fact_order_items') }}
WHERE product_key IS NULL
   OR seller_key IS NULL
   OR date_key IS NULL
