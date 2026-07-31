-- depends_on: {{ ref('dim_product') }}
-- depends_on: {{ ref('dim_seller') }}
-- depends_on: {{ ref('dim_date') }}
-- depends_on: {{ ref('fact_orders') }}
-- depends_on: {{ ref('dim_customer') }}

{{ metadata_join('fact_order_items', 'foi') }}