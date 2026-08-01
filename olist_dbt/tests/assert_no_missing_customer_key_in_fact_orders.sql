SELECT order_id, customer_key
FROM {{ ref('fact_orders') }}
WHERE customer_key IS NULL
