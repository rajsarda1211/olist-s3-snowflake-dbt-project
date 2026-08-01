-- Guards against a snapshot bug producing two "current" rows for the same seller,
-- which would cause fanout in any join using is_current = TRUE
SELECT
    seller_id,
    COUNT(*) AS current_row_count
FROM {{ ref('dim_seller') }}
WHERE is_current = TRUE
GROUP BY seller_id
HAVING COUNT(*) > 1
