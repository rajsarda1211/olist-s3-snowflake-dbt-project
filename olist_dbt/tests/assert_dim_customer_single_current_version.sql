-- Guards against a snapshot bug producing two "current" rows for the same customer,
-- which would cause fanout in any join using is_current = TRUE
SELECT
    customer_unique_id,
    COUNT(*) AS current_row_count
FROM {{ ref('dim_customer') }}
WHERE is_current = TRUE
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
