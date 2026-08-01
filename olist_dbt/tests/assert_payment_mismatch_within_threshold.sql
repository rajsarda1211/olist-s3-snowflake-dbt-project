-- Fails only if more than 5% of orders show a large payment/order value mismatch.
-- Some mismatch is expected (credit card installment financing), this catches abnormal spikes.

WITH mismatch_stats AS (
    SELECT
        COUNT(*) AS total_orders,
        COUNT(CASE WHEN ABS(total_payment_value - total_order_value) > 5 THEN 1 END) AS mismatched_orders
    FROM {{ ref('fact_orders') }}
)

SELECT
    total_orders,
    mismatched_orders,
    ROUND(100.0 * mismatched_orders / total_orders, 2) AS mismatch_pct
FROM mismatch_stats
WHERE (100.0 * mismatched_orders / total_orders) > 5.0
