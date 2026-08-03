USE ROLE LOADER_ROLE;
USE WAREHOUSE LOADING_WH;
USE SCHEMA OLIST_DB.BRONZE_SCHEMA;

-- CUSTOMERS PIPE

CREATE OR REPLACE PIPE pipe_raw_customers
    AUTO_INGEST = TRUE
AS
COPY INTO raw_customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state, _source_file, _row_hash)
FROM (
    SELECT $1, $2, $3, $4, $5,
        METADATA$FILENAME,
        MD5($1||'|'||$2||'|'||$3||'|'||$4||'|'||$5)
    FROM @olist_s3_stage/customers/
)
FILE_FORMAT = (FORMAT_NAME = csv_format);

-- ORDER PIPE

CREATE OR REPLACE PIPE pipe_raw_orders
    AUTO_INGEST = TRUE
AS
COPY INTO raw_orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date, _source_file, _row_hash)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7, $8,
        METADATA$FILENAME,
        MD5($1||'|'||$2||'|'||$3||'|'||$4||'|'||$5||'|'||$6||'|'||$7||'|'||$8)
    FROM @olist_s3_stage/orders/
)
FILE_FORMAT = (FORMAT_NAME = csv_format);


-- ORDER ITEMS PIPE

CREATE OR REPLACE PIPE pipe_raw_order_items
  AUTO_INGEST = TRUE
AS
COPY INTO raw_order_items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value, _source_file, _row_hash)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7,
        METADATA$FILENAME,
        MD5($1||'|'||$2||'|'||$3||'|'||$4||'|'||$5||'|'||$6||'|'||$7)
    FROM @olist_s3_stage/order_items/
)
FILE_FORMAT = (FORMAT_NAME = csv_format);


-- ORDER PAYMENTS PIPE

CREATE OR REPLACE PIPE pipe_raw_order_payments
  AUTO_INGEST = TRUE
AS
COPY INTO raw_order_payments (order_id, payment_sequential, payment_type, payment_installments, payment_value, _source_file, _row_hash)
FROM (
    SELECT $1, $2, $3, $4, $5,
        METADATA$FILENAME,
        MD5($1||'|'||$2||'|'||$3||'|'||$4||'|'||$5)
    FROM @olist_s3_stage/order_payments/
)
FILE_FORMAT = (FORMAT_NAME = csv_format);


-- ORDER REVIEWS PIPE

CREATE OR REPLACE PIPE pipe_raw_order_reviews
  AUTO_INGEST = TRUE
AS
COPY INTO raw_order_reviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp, _source_file, _row_hash)
FROM (
    SELECT $1, $2, $3, $4, $5, $6, $7,
        METADATA$FILENAME,
        MD5($1||'|'||$2||'|'||$3||'|'||$4||'|'||$5||'|'||$6||'|'||$7)
    FROM @olist_s3_stage/order_reviews/
)
FILE_FORMAT = (FORMAT_NAME = csv_format);


-- Get SQS ARNs 
SHOW PIPES LIKE 'pipe_raw_%';

-- Check row counts landed
SELECT 'orders' AS tbl, COUNT(*) FROM raw_orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM raw_order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM raw_order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM raw_order_reviews;