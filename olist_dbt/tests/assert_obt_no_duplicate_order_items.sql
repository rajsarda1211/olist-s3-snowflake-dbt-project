SELECT
    order_id,
    order_item_id,
    COUNT(*) AS row_count
FROM {{ ref('obt_orders') }}
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
