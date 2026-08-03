USE ROLE LOADER_ROLE;
USE WAREHOUSE LOADING_WH;
USE SCHEMA OLIST_DB.BRONZE_SCHEMA;

-- 1. SELLERS

COPY INTO raw_sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state, _source_file, _row_hash)
FROM (
    SELECT 
        $1, $2, $3, $4,
        METADATA$FILENAME,
        MD5($1 || '|' || $2 || '|' || $3 || '|' || $4)
    FROM @olist_s3_stage/sellers/
)
FILE_FORMAT = (FORMAT_NAME = csv_format)
ON_ERROR = 'ABORT_STATEMENT';


-- 2. PRODUCTS


COPY INTO raw_products 
    (product_id, product_category_name, product_name_lenght, product_description_lenght,
     product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm,
     _source_file, _row_hash)
FROM (
    SELECT 
        $1, $2, $3, $4, $5, $6, $7, $8, $9,
        METADATA$FILENAME,
        MD5($1 || '|' || $2 || '|' || $3 || '|' || $4 || '|' || $5 || '|' || $6 || '|' || $7 || '|' || $8 || '|' || $9)
    FROM @olist_s3_stage/products/
)
FILE_FORMAT = (FORMAT_NAME = csv_format)
ON_ERROR = 'ABORT_STATEMENT';


-- 3. PRODUCT CATEGORY TRANSLATION

COPY INTO raw_product_category (product_category_name, product_category_name_english, _source_file, _row_hash)
FROM (
    SELECT 
        $1, $2,
        METADATA$FILENAME,
        MD5($1 || '|' || $2)
    FROM @olist_s3_stage/product_category/
)
FILE_FORMAT = (FORMAT_NAME = csv_format)
ON_ERROR = 'ABORT_STATEMENT';


-- 5. GEOLOCATION

COPY INTO raw_geolocation 
    (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state, 
     _source_file, _row_hash)
FROM (
    SELECT 
        $1, $2, $3, $4, $5,
        METADATA$FILENAME,
        MD5($1 || '|' || $2 || '|' || $3 || '|' || $4 || '|' || $5)
    FROM @olist_s3_stage/geolocation/
)
FILE_FORMAT = (FORMAT_NAME = csv_format)
ON_ERROR = 'ABORT_STATEMENT';


-- Validate all 5 loads

SELECT 'customers' AS tbl, COUNT(*) AS row_count FROM raw_customers
UNION ALL
SELECT 'sellers' AS tbl , COUNT(*) AS row_count FROM raw_sellers
UNION ALL
SELECT 'products', COUNT(*) FROM raw_products
UNION ALL
SELECT 'product_category', COUNT(*) FROM raw_product_category
UNION ALL
SELECT 'geolocation', COUNT(*) FROM raw_geolocation;



