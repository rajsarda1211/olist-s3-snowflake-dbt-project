# Olist E-Commerce Data Pipeline — Snowflake + dbt

An end-to-end data engineering project built on the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), implementing a full Medallion Architecture (Bronze → Silver → Gold) on Snowflake, with CDC, SCD Type 2, incremental loading, a metadata-driven One Big Table, role-based access control, and a 137-test data quality framework — all validated through a real incremental/SCD2 simulation, not just a static build.

---

## 1. Project Overview

This project simulates a production-grade analytics pipeline for an e-commerce marketplace. Raw CSV data lands in AWS S3, is ingested into Snowflake via a mix of Snowpipe (event-driven) and COPY INTO (batch), transformed through dbt across Bronze/Silver/Gold layers, and modeled into a star schema with full historical tracking on key dimensions.

The goal was not just to build a working pipeline once, but to **prove it correctly handles change** — new records, updated records, and multi-version dimensional history — through a deliberate, documented simulation exercise.

---

## 2. Business Objective

Build a warehouse capable of answering real business questions without requiring analysts to write complex multi-table joins every time:

- Which product categories generate the most revenue?
- Which states drive the most business, and which have the most satisfied customers?
- What is a seller's average rating, and how does delivery performance vary by region?
- How do returning customers' order patterns change over time?

---

## 3. Dataset Overview

9 source tables from the Olist dataset:

| Table | Description |
|---|---|
| `orders` | Order-level data, status, timestamps |
| `order_items` | Line items per order — product, seller, price, freight |
| `order_payments` | Payment method, installments, value |
| `order_reviews` | Customer satisfaction reviews |
| `customers` | Order-customer bridge — **not** a customer master table (see Design Decisions) |
| `sellers` | Seller location |
| `products` | Product catalog, dimensions, category |
| `product_category_name_translation` | Portuguese → English category lookup |
| `geolocation` | Brazilian zip code → lat/lng mapping |

---

## 4. Technology Stack

| Layer | Tools |
|---|---|
| Storage | AWS S3 |
| Warehouse | Snowflake |
| Transformation | dbt Core (dbt-snowflake) |
| Ingestion | Snowpipe (auto), COPY INTO (batch) |
| CDC | Snowflake Streams + metadata columns (`_source_file`, `_loaded_at`, `_row_hash`) |
| Testing | dbt generic + singular tests, dbt-utils, dbt contracts |
| Version Control | Git / GitHub |
| Environment | Python `uv`, VS Code with dbt Power User |

---

## 5. Architecture Overview

```
S3 (raw CSVs)
    ↓
Snowflake Bronze  ← built via Snowsight SQL (NOT dbt)
    ↓
dbt: Silver → Snapshots → Gold Dims/Facts → OBT
```

**Important distinction — what was built where:**

| Layer | Built with |
|---|---|
| RBAC, warehouses, Storage Integration, Stage, file format, Bronze table DDL, Snowpipe, COPY INTO, Streams | **Snowflake SQL, via Snowsight — not dbt** |
| Silver models, Snapshots, Gold dims/facts, OBT, tests, macros, seeds | **dbt** |

This separation was deliberate: dbt is a transformation tool, not an infrastructure/ingestion tool. Snowflake-native features (Snowpipe, Streams, Storage Integration) have no dbt equivalent and were built directly in Snowflake.

---

## 6. AWS S3 Data Lake Setup

One folder per table:
```
s3://olist-dataset-raj/
├── customers/       ← Snowpipe (transactional — new order-customer rows continuously)
├── sellers/         ← COPY INTO (reference data)
├── products/        ← COPY INTO
├── product_category/← COPY INTO
├── geolocation/      ← COPY INTO
├── orders/          ← Snowpipe
├── order_items/     ← Snowpipe
├── order_payments/  ← Snowpipe
└── order_reviews/   ← Snowpipe
```

**A note on `customers`:** Initially treated as reference data (COPY INTO), but corrected mid-project — since Olist's `customers` table is order-driven (a new row is created per order, not per unique person), it is transactional in nature and was moved to Snowpipe.

### IAM Role → IAM User pivot

The original design used an IAM Role with cross-account `sts:AssumeRole` trust (the AWS-recommended pattern — no static credentials, short-lived tokens). After ~2 days of debugging a persistent `AssumeRole` authorization failure (confirmed correct ARNs, correct External ID, ruled out propagation delay, ruled out permissions boundaries) with no resolution, the decision was made to switch to an **IAM User with static access keys** embedded in the Snowflake Stage definition.

This was a deliberate tradeoff, not an oversight: static keys are simpler and unblocked the project, at the cost of the security benefits of temporary, auto-rotating credentials. In a production system, the IAM Role pattern would be the correct choice. Credentials were kept out of version control via a template file + `.gitignore`.

---

## 7. Snowflake Infrastructure (Built via Snowsight)

### 7.1 RBAC

Three roles, each scoped to a specific layer:

| Role | Access |
|---|---|
| `LOADER_ROLE` | Full control on Bronze schema only. Owns Storage Integration, Stage, Pipes, Streams. |
| `TRANSFORMER_ROLE` | Read-only on Bronze, full control on Silver/Gold. This is what dbt connects as. |
| `ANALYST_ROLE` | Read-only on Gold only. |

Role creation via `SECURITYADMIN`, database/schema/warehouse objects via `SYSADMIN` — following Snowflake's intended privilege separation (note: `CREATE INTEGRATION` required an explicit one-time grant from `ACCOUNTADMIN` to `SYSADMIN`, since it's not included by default).

### 7.2 Warehouses

Three warehouses, isolating compute by workload for cost tracking:
- `LOADING_WH` — ingestion
- `TRANSFORM_WH` — dbt runs
- `ANALYSIS_WH` — BI/analyst queries

### 7.3 CDC Strategy

Two-part CDC approach:
1. **Metadata columns** stamped on every Bronze row at ingestion: `_source_file` (via `METADATA$FILENAME`), `_loaded_at` (default `CURRENT_TIMESTAMP()`), `_row_hash` (MD5 of business columns)
2. **Snowflake Streams** on all 9 Bronze tables, tracking every INSERT for downstream consumption

### 7.4 Ingestion split

- **Snowpipe (event-driven, SQS-triggered)**: `orders`, `order_items`, `order_payments`, `order_reviews`, `customers`
- **COPY INTO (manual/batch)**: `sellers`, `products`, `product_category`, `geolocation`

---

## 8. Bronze Layer

Raw, untransformed data — one table per source file, all columns as `STRING`, plus the 3 CDC metadata columns. No filtering, no casting, no business logic. This is the permanent audit layer.

---

## 9. Silver Layer (dbt)

Cleaned, typed, deduplicated models — one per Bronze table (with `products` absorbing `product_category` via a join).

**Key transformations:**
- `TRY_CAST()` type casting (never hard `CAST`, to avoid failing the whole load on one bad row)
- `clean_string` macro (LOWER + TRIM) on city/state fields
- Typo correction (`product_name_lenght` → `product_name_length`)
- Deduplication via `QUALIFY ROW_NUMBER() ... ORDER BY _loaded_at DESC` on all tables where the same natural key can reappear (critical for correct incremental MERGE behavior — see Challenges section)
- `stg_geolocation` deduplicates many-to-one zip codes via `AVG(lat/lng)` aggregation

**Materialization:** Incremental for all transactional tables (customers, orders, order_items, order_payments, order_reviews), `table` for static reference data (sellers, products, geolocation).

**dbt Contracts** (`contract: enforced: true`) are used throughout Silver and Gold — this enforces real column types and `NOT NULL` constraints in the generated Snowflake DDL, since Snowflake itself does not enforce constraints at the engine level by default.

---

## 10. SCD Type 2 Design

Three dimensions carry full history via dbt Snapshots (`check` strategy):

| Snapshot | Natural key | Tracked columns |
|---|---|---|
| `snp_customers` | `customer_unique_id` | city, state, zip |
| `snp_products` | `product_id` | category, weight, length |
| `snp_sellers` | `seller_id` | city, state, zip |

Snapshots read from Silver, deduplicated to one row per natural key (ordered by the customer's most recent order, not ingestion time — see Challenges section for why this matters). Gold dimension tables read from the snapshots and add a surrogate key (`dbt_utils.generate_surrogate_key`) combining the natural key with `dbt_valid_from`.

---

## 11. Gold Layer

### 11.1 Star Schema

![Star Schema Diagram](olist_star_schema.png)

### 11.2 Dimensions

| Table | Type | Notes |
|---|---|---|
| `dim_customer` | SCD2 | City/state/zip only — no lat/lng (see Design Decisions) |
| `dim_product` | SCD2 | Category, dimensions |
| `dim_seller` | SCD2 | City/state/zip |
| `dim_location` | Static | Standalone zip → lat/lng, not joined into OBT by default |
| `dim_date` | Generated | Date spine covering 2016–2027 (extended for simulation testing) |

### 11.3 Facts

| Table | Grain | Materialization |
|---|---|---|
| `fact_orders` | One row per order | Incremental |
| `fact_order_items` | One row per order line item | Incremental |

Both join to SCD2 dimensions using a **date-range join** (order date falls within `dbt_valid_from`/`dbt_valid_to`), with a fallback to the current version for orders that predate all snapshot history. See Known Limitations for what this fallback does and doesn't guarantee.

### 11.4 One Big Table (Metadata-Driven)

`obt_orders` is built almost entirely by a single macro call:

```sql
{{ metadata_join('fact_order_items', 'foi') }}
```

`metadata_join` reads `seeds/obt_join_config.csv` at compile time via `run_query()`, and dynamically generates every JOIN clause. **Adding a new dimension to the OBT requires only a new row in the CSV — zero SQL changes.**

---

## 12. Data Quality & Testing Framework

**137 tests**, spanning:
- Generic tests (`not_null`, `unique`, `accepted_values`, `relationships`) on every model
- Composite uniqueness tests (`dbt_utils.unique_combination_of_columns`) on multi-column grains
- 18 custom singular tests covering:
  - Row count consistency at every layer boundary (Bronze→Silver, Silver→Gold)
  - Fanout detection (duplicate rows from bad joins)
  - SCD2 entity-count checks (distinct natural keys must match across layers, not raw row counts — see Design Decisions)
  - "Exactly one current version" checks per SCD2 entity
  - Aggregate sum consistency between layers
  - Payment/order value mismatch monitoring (threshold-based, not zero-tolerance — see Business Insights)

---

## 13. SCD2 & Incremental Simulation — Proof of Work

Rather than assume the pipeline handles change correctly, it was proven through a deliberate two-batch simulation:

**Batch 1:** Two new orders uploaded with delivery date left NULL ("in transit"). One order for a returning customer at a new location (triggering SCD2 v2), one for a brand-new customer.

**Batch 2:** The **same two order_ids** re-uploaded with delivery data now filled in — testing that the incremental MERGE updates the existing row rather than duplicating it. Simultaneously, a third version of the same customer's location was added (third order, third address) to prove a 3-deep SCD2 chain, not just a single before/after.

**Result — all verified with live queries:**
- `dim_customer` correctly shows 3 versions for the target customer, with the middle version having both `dbt_valid_from` and `dbt_valid_to` populated
- The two Batch-1 orders show `COUNT(*) = 1` each after Batch 2 — confirmed no duplicate was created
- Total simulated order count after both batches: exactly 3 (not 5) — proving 2 of the 5 uploaded order records were correctly treated as updates
- Zero fanout across the entire `obt_orders` table

Screenshot evidence: `[insert: dim_customer 3-version query result]`, `[insert: order COUNT(*)=1 no-duplicate query result]`, `[insert: dbt test 137/137 passing]`

---

## 14. Business Insights Discovered

**Duplicate `review_id` values across different orders** — investigation revealed this isn't a data bug: the same real customer (`customer_unique_id`) placing multiple orders can have one review linked across multiple `order_id`s, and conversely the same order can receive multiple reviews from a returning customer. The true grain of the reviews table is `review_id + order_id`, not either column alone.

**`total_payment_value` exceeding `total_order_value`** — investigated via a targeted query comparing installment counts between mismatched and overall order populations. Mismatched orders averaged **8.1 installments** vs **3.5** for the overall credit card population — confirming the gap reflects real financing/interest costs on installment purchases, not a pipeline defect.

---

## 15. Key Design Decisions & Tradeoffs

- **`customer_id` vs `customer_unique_id`**: Olist's `customers` table is an order-customer bridge, not a master record — `customer_id` is unique per order, `customer_unique_id` identifies the real person. This distinction shapes the entire customer dimension design.
- **Star schema over snowflake schema**: `dim_customer`/`dim_seller` intentionally keep city/state/zip inline rather than referencing `dim_location`, favoring the star schema's query-simplicity philosophy over normalization.
- **Defensive modeling over silent filtering**: bad/orphaned rows are not silently dropped in Silver; referential integrity is enforced via tests, keeping data quality issues visible rather than hidden.
- **QUALIFY ROW_NUMBER() over correlated NOT EXISTS**: the SCD2 join fallback logic was rewritten from a correlated subquery to a window-function pattern after hitting a genuine Snowflake internal optimizer error at scale — same logical result, more optimizer-friendly execution plan.

---

## 16. Challenges & Bugs Found (and Fixed)

| Issue | Root Cause | Fix |
|---|---|---|
| AssumeRole failure (2 days) | Unresolved despite correct config | Pivoted to IAM User with static keys |
| Fanout in fact tables | SCD2 fallback join could double-match once real history existed | Rewrote using `QUALIFY ROW_NUMBER()` ranking |
| `is_late_delivery` misclassifying undelivered orders as on-time | `NULL > date` evaluates to NULL, fell through to `ELSE FALSE` | Explicit `WHEN NULL THEN NULL` branch |
| Snowflake internal error (000603) on fact rebuild | Correlated `NOT EXISTS` subquery hit an optimizer limitation at scale | Replaced with `QUALIFY ROW_NUMBER()` |
| Duplicate-row MERGE error during simulation | Same `order_id` appeared twice within the incremental lookback window (Batch 1 + Batch 2) | Added `QUALIFY ROW_NUMBER()` deduplication to all transactional Silver models |
| Missing `dim_date` coverage | Date spine only covered 2016–2020 (real data range); simulation used 2026 dates | Extended range to 2016–2027 |
| Customer's "current" address selected by ingestion time, not order recency | Snapshot source ordered by `_loaded_at` instead of `order_purchase_timestamp` | Joined to `stg_orders`, reordered by actual order date |

---

## 17. Known Limitations

**Pre-tracking historical attribution:** SCD2 snapshot tracking began when this project's snapshots were first run (2026), while real Olist order data spans 2016–2020. Orders that predate any snapshot history will always resolve to the *current* dimensional state at query time, not their true historical state, since that history was never captured. This is an inherent, unavoidable limitation of retroactively applying SCD2 to pre-existing historical data — not a pipeline defect. In a live system where SCD2 tracking runs from the point data first enters the system, this limitation would not exist.

**`_row_hash` can be NULL** when concatenated source fields contain a NULL (e.g., an undelivered order's delivery timestamp), since Snowflake's `||` operator propagates NULLs. Not currently used for deduplication logic, so non-blocking; a production fix would wrap each field in `COALESCE()` before concatenation.

---

## 18. Project Structure

```
olist_dbt/
├── models/
│   ├── silver/          # staging models, sources.yml
│   └── gold/
│       ├── dims/
│       ├── facts/
│       └── obt/
├── snapshots/            # SCD2 snapshots
├── macros/                # clean_string, cast_monetary, metadata_join
├── seeds/                 # obt_join_config.csv
├── tests/                 # 18 singular tests
└── dbt_project.yml
```

---

## 19. Future Improvements

- Orchestration (Airflow/Dagster) to automate the run sequence and remove manual `dbt run`/`dbt snapshot` ordering
- Point-in-time attribution improvements for pre-tracking historical orders (acknowledged as unrecoverable, but hybrid heuristics could reduce the gap)
- `_row_hash` NULL-safety via `COALESCE()`
- BI dashboard layer on top of `obt_orders`

---

## Author's Note

Every architectural decision, bug, and fix documented above was found and resolved through direct hands-on debugging — including a genuine 2-day AWS IAM troubleshooting effort, a Snowflake internal optimizer error, and a deliberately designed 2-batch simulation to prove (not assume) that the incremental and SCD2 logic works correctly under real change conditions.
