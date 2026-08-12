import pandas as pd
from google.cloud import bigquery
import psycopg2


conn = psycopg2.connect(
    host="postgres-olist-airflow",
    port=5432,
    database="olist",
    user="root",
    password="root"
)


client = bigquery.Client.from_service_account_json(
    "/usr/local/airflow/include/credentials/olist-data-warehouse.json",
    project="olist-data-warehouse-504705"
)


tables = [
    "customers",
    "orders",
    "order_items",
    "products",
    "sellers",
    "order_payments",
    "order_reviews",
    "geolocation",
    "product_category_translation"
]


for table in tables:

    print(f"\nUploading {table}...")

    # Read table from PostgreSQL
    df = pd.read_sql(f"SELECT * FROM raw.{table};", conn)

    # Destination table in BigQuery
    table_id = f"olist-data-warehouse-504705.raw_postgres.{table}"

  
    job = client.load_table_from_dataframe(
        df,
        table_id,
        job_config=bigquery.LoadJobConfig(
            write_disposition="WRITE_TRUNCATE"  # Replace table if it already exists
        )
    )

    job.result()

    print(f"✓ {table} uploaded successfully ({len(df)} rows)")

conn.close()

print("\nAll tables uploaded successfully!")