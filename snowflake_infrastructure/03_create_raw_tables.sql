USE ROLE LOADER_ROLE;
USE WAREHOUSE LOADING_WH;
USE SCHEMA OLIST_DB.BRONZE_SCHEMA;

-- 1. CUSTOMERS

CREATE OR REPLACE TABLE raw_customers (
    customer_id STRING,
    customer_unique_id STRING,
    customer_zip_code_prefix STRING,
    customer_city STRING,
    customer_state STRING,
    _source_file STRING,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _row_hash STRING
);

-- 2. SELLERS

CREATE OR REPLACE TABLE raw_sellers (
    seller_id STRING,
    seller_zip_code_prefix STRING,
    seller_city STRING,
    seller_state STRING,
    _source_file STRING,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _row_hash STRING
);

-- 3. PRODUCTS

CREATE OR REPLACE TABLE raw_products (
    product_id STRING,
    product_category_name STRING,
    product_name_lenght STRING,
    product_description_lenght STRING,
    product_photos_qty STRING,
    product_weight_g STRING,
    product_length_cm STRING,
    product_height_cm STRING,
    product_width_cm STRING,
    _source_file STRING,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _row_hash STRING
);

-- 4. PRODUCT CATEGORY TRANSLATION

CREATE OR REPLACE TABLE raw_product_category (
    product_category_name STRING,
    product_category_name_english STRING,
    _source_file STRING,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _row_hash STRING
);

-- 5. GEOLOCATION

CREATE OR REPLACE TABLE raw_geolocation (
    geolocation_zip_code_prefix STRING,
    geolocation_lat STRING,
    geolocation_lng STRING,
    geolocation_city STRING,
    geolocation_state STRING,
    _source_file STRING,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _row_hash STRING
);

-- 6. ORDERS

CREATE OR REPLACE TABLE raw_orders (
    order_id STRING,
    customer_id STRING,
    order_status STRING,
    order_purchase_timestamp STRING,
    order_approved_at STRING,
    order_delivered_carrier_date STRING,
    order_delivered_customer_date STRING,
    order_estimated_delivery_date STRING,
    _source_file STRING,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _row_hash STRING
);

-- 7. ORDER ITEMS

CREATE OR REPLACE TABLE raw_order_items (
    order_id STRING,
    order_item_id STRING,
    product_id STRING,
    seller_id STRING,
    shipping_limit_date STRING,
    price STRING,
    freight_value STRING,
    _source_file STRING,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _row_hash STRING
);

-- 8. ORDER 

CREATE OR REPLACE TABLE raw_order_payments (
    order_id STRING,
    payment_sequential STRING,
    payment_type STRING,
    payment_installments STRING,
    payment_value STRING,
    _source_file STRING,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _row_hash STRING
);

-- 9. ORDER REVIEWS

CREATE OR REPLACE TABLE raw_order_reviews (
    review_id STRING,
    order_id STRING,
    review_score STRING,
    review_comment_title STRING,
    review_comment_message STRING,
    review_creation_date STRING,
    review_answer_timestamp STRING,
    _source_file STRING,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    _row_hash STRING
);
