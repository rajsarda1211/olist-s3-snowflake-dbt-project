USE ROLE LOADER_ROLE;
USE WAREHOUSE LOADING_WH;
USE SCHEMA OLIST_DB.BRONZE_SCHEMA;

-- Create Stream

CREATE OR REPLACE STREAM stream_raw_customers ON TABLE raw_customers;
CREATE OR REPLACE STREAM stream_raw_sellers ON TABLE raw_sellers;
CREATE OR REPLACE STREAM stream_raw_products ON TABLE raw_products;
CREATE OR REPLACE STREAM stream_raw_product_category ON TABLE raw_product_category;
CREATE OR REPLACE STREAM stream_raw_geolocation ON TABLE raw_geolocation;
CREATE OR REPLACE STREAM stream_raw_orders ON TABLE raw_orders;
CREATE OR REPLACE STREAM stream_raw_order_items ON TABLE raw_order_items;
CREATE OR REPLACE STREAM stream_raw_order_payments ON TABLE raw_order_payments;
CREATE OR REPLACE STREAM stream_raw_order_reviews ON TABLE raw_order_reviews;

-- Verification 

SHOW STREAMS IN SCHEMA OLIST_DB.BRONZE_SCHEMA;


SELECT 'customers' AS tbl, COUNT(*) FROM stream_raw_customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM stream_raw_sellers
UNION ALL
SELECT 'products', COUNT(*) FROM stream_raw_products
UNION ALL
SELECT 'product_category', COUNT(*) FROM stream_raw_product_category
UNION ALL
SELECT 'geolocation', COUNT(*) FROM stream_raw_geolocation
UNION ALL
SELECT 'orders', COUNT(*) FROM stream_raw_orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM stream_raw_order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM stream_raw_order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM stream_raw_order_reviews;