# Retail Analytics ELT Pipeline

An end-to-end data engineering capstone for the Olist e-commerce dataset. The project ingests data from PostgreSQL into BigQuery, transforms it with dbt into a tested star schema, and orchestrates the full workflow with Apache Airflow.

## Architecture

```text
PostgreSQL (Olist)
        |
        | Python ingestion
        v
BigQuery raw_dataset
        |
        | dbt source()
        v
Staging models (stg_*)
        |
        | dbt ref()
        v
Analytics marts
  |-------------------------------|
  |                               |
  v                               v
Dimensions                     Fact
- dim_customers               - fct_order_items
- dim_products
- dim_sellers
- dim_date
        |
        v
Analysis queries

Orchestration: Airflow
PostgreSQL -> ingest -> dbt run -> dbt test
```

## Project structure

```text
retail_analytics_project/
├── analyses/
│   ├── 01_top_products.sql
│   ├── 02_top_customers.sql
│   ├── 03_top_sellers.sql
│   ├── 04_top_categories.sql
│   └── 05_monthly_sales.sql
├── models/
│   ├── staging/
│   │   └── stg_*.sql
│   └── marts/
│       ├── dim_customers.sql
│       ├── dim_products.sql
│       ├── dim_sellers.sql
│       ├── dim_date.sql
│       ├── fct_order_items.sql
│       └── marts.yml
├── tests/
│   ├── assert_fct_order_items_unique.sql
│   ├── assert_order_item_freight_non_negative.sql
│   └── assert_order_item_price_non_negative.sql
├── dbt_project.yml
└── README.md
```

The local Airflow project is maintained separately and contains the ingestion script, dbt project copy, credentials/configuration for local execution, and the Airflow DAG.

## Data flow

### 1. Ingestion

A Python script extracts the Olist tables from PostgreSQL and loads them into the BigQuery `raw_dataset` dataset.

The ingestion currently uses `WRITE_TRUNCATE`, so each ingestion refreshes the raw tables rather than appending duplicate copies.

Loaded source tables include:

- `olist_orders_dataset`
- `olist_order_items_dataset`
- `olist_order_payments_dataset`
- `olist_order_reviews_dataset`
- `olist_customers_dataset`
- `olist_sellers_dataset`
- `olist_products_dataset`
- `olist_geolocation_dataset`
- `product_category_name_translation`

### 2. Staging

The staging layer uses `source()` and is responsible for cleaning and standardizing raw data without introducing analytical business logic.

Examples include:

- safe timestamp casting with `SAFE_CAST`
- empty-string handling with `NULLIF`
- whitespace cleanup with `TRIM`
- text standardization with `LOWER`, `UPPER`, and `INITCAP`
- correcting source column naming issues such as `product_name_lenght` -> `product_name_length`

### 3. Marts

The marts layer uses `ref()` and builds the analytical star schema.

#### Dimensions

- `dim_customers` — customer identifiers and location attributes
- `dim_products` — product attributes plus English category translation
- `dim_sellers` — seller identifiers and location attributes
- `dim_date` — generated calendar dimension

#### Fact

`fct_order_items` has the agreed grain:

> One row = one item line within an order.

The fact contains:

- Keys: `order_id`, `order_item_id`, `product_id`, `seller_id`, `customer_id`, `order_date`
- Order attribute: `order_status`
- Measures: `price`, `freight_value`
- Technical/incremental timestamp: `order_purchase_ts`

Descriptive attributes such as category, city, and state remain in the dimensions rather than being duplicated onto the fact.

## Fact table design

### Grain

The fact table is at order-item grain. The logical primary key is:

```text
(order_id, order_item_id)
```

A composite-key custom test verifies that this combination remains unique.

### Avoiding fan-out

Payments and reviews were intentionally not joined into `fct_order_items` because they are at different grains from order items. Joining them directly could multiply rows and cause incorrect aggregates.

## Incremental processing and idempotency

`fct_order_items` is an incremental dbt model using BigQuery `MERGE`:

```sql
materialized='incremental'
unique_key=['order_id', 'order_item_id']
incremental_strategy='merge'
```

Because the Olist dataset does not provide a reliable source `updated_at`, the model uses a 7-day lookback based on `order_purchase_ts`:

```sql
WHERE order_purchase_ts >=
      MAX(order_purchase_ts already present) - 7 days
```

This allows recent rows to be reconsidered for late-arriving or recent changes while the composite unique key prevents duplicate fact rows during merge.

### Incremental validation performed

The incremental behavior was verified with:

1. An initial load of 112,650 fact rows.
2. A repeat incremental run with the same data, which kept the fact at 112,650 rows.
3. A controlled update test, where a target row was temporarily changed and the incremental merge restored the source value.
4. A two-batch simulation:
   - Batch 1: 112,550 fact rows after holding back 100 order-item rows.
   - Batch 2: restored the 100 held-back rows.
   - Final fact: exactly 112,650 rows with 112,650 unique order-item keys.

This demonstrates that re-running the pipeline on the same data does not create duplicates and that new data can be merged into the fact.

> Note: the two-batch test is a controlled simulation because the Olist dataset is static rather than a live change-data-capture source.

## BigQuery optimization

`fct_order_items` is physically optimized with:

```sql
partition_by={
    "field": "order_date",
    "data_type": "date",
    "granularity": "day"
}
cluster_by=["product_id", "seller_id"]
```

### Partitioning

The table is partitioned by `order_date`, allowing BigQuery to prune irrelevant date partitions for date-filtered queries.

### Clustering

Within partitions, the table is clustered by `product_id` and `seller_id`, which helps queries that frequently filter, group, or join on those columns.

## Data quality tests

The project includes 23 dbt data tests covering:

- `not_null` checks on required keys
- `unique` checks on dimension primary keys
- foreign-key `relationships` checks from fact to dimensions
- accepted values for `order_status`
- composite fact-grain uniqueness
- `price >= 0`
- `freight_value >= 0`

The test suite has been verified with:

```text
PASS=23
ERROR=0
```

## Airflow orchestration

The production-style local pipeline is orchestrated with Apache Airflow using Astro CLI.

DAG dependency:

```text
ingest >> dbt_run >> dbt_test
```

### Tasks

1. `ingest`
   - PostgreSQL -> BigQuery raw ingestion
2. `dbt_run`
   - builds staging and mart models
3. `dbt_test`
   - validates the warehouse models

The DAG is scheduled daily and configured with retries. A failed upstream task blocks downstream tasks, and failures are visible in the Airflow UI and task logs.

## dbt documentation and lineage

Documentation is generated with:

```bash
dbt docs generate --profiles-dir /usr/local/airflow/include/dbt_profiles
```

The lineage graph shows the flow from raw sources through staging and marts into analysis queries and data-quality tests.

Key lineage path:

```text
raw tables
   -> staging models
   -> dimensions / fct_order_items
   -> analysis queries
```

## Business analysis

The project includes analysis queries answering questions such as:

- Which products generate the most sales?
- Which customers spend the most?
- Which sellers generate the most sales?
- Which product categories generate the most sales?
- How do sales change month to month?

### Example: top products by sales

The analysis aggregates `price` from `fct_order_items`, joins to `dim_products`, excludes canceled/unavailable orders, and ranks products by total sales.

Useful metrics include:

- total sales
- order-item count
- distinct order count
- average item price
- share of total sales

## How to run locally

### dbt

Activate the project environment and run:

```bash
dbt run
dbt test
```

For the local Astro environment, dbt commands use the profile mounted at:

```text
/usr/local/airflow/include/dbt_profiles
```

Example:

```bash
dbt run --profiles-dir /usr/local/airflow/include/dbt_profiles
dbt test --profiles-dir /usr/local/airflow/include/dbt_profiles
```

### Airflow

From the local Astro project:

```powershell
astro dev start
```

Then open the Airflow UI at:

```text
http://localhost:8080
```

The main DAG is:

```text
retail_analytics_pipeline
```


## Key modeling decisions

- Staging uses `source()` and focuses on cleanup/standardization.
- Marts use `ref()` and implement the analytical model.
- Fact grain is one row per order item.
- `order_id + order_item_id` is the fact's logical key.
- Payments and reviews are not joined into the item-level fact because of grain mismatch.
- Dimensions hold descriptive attributes; the fact holds keys, measures, and required filtering attributes.
- The fact is incremental, partitioned by `order_date`, and clustered by `product_id` and `seller_id`.

