-- Guards against a snapshot bug producing two "current" rows for the same product,
-- which would cause fanout in any join using is_current = TRUE
SELECT
    product_id,
    COUNT(*) AS current_row_count
FROM {{ ref('dim_product') }}
WHERE is_current = TRUE
GROUP BY product_id
HAVING COUNT(*) > 1
