import os
import pandas as pd
from sqlalchemy import create_engine
from google.cloud import bigquery

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = (
    "/usr/local/airflow/include/de-project-504705-51a0e32c153a.json"
)

PG_USER = "postgres"
PG_PASSWORD = "postgres"
PG_HOST = "host.docker.internal"
PG_PORT = "5432"
PG_DATABASE = "postgres"

PROJECT_ID = "de-project-504705"
DATASET_ID = "raw_dataset"
LOCATION = "US"

print("Connecting to PostgreSQL...")
pg_engine = create_engine(
    f"postgresql://{PG_USER}:{PG_PASSWORD}@{PG_HOST}:{PG_PORT}/{PG_DATABASE}"
)

print("Initializing Google BigQuery Client...")
bq_client = bigquery.Client(project=PROJECT_ID)

dataset_ref = f"{PROJECT_ID}.{DATASET_ID}"
dataset = bigquery.Dataset(dataset_ref)
dataset.location = LOCATION
dataset = bq_client.create_dataset(dataset, exists_ok=True)
print(f"BigQuery Dataset Ready: {dataset_ref}\n" + "-" * 50)

tables_to_ingest = [
    "olist_orders_dataset",
    "olist_order_items_dataset",
    "olist_order_payments_dataset",
    "olist_order_reviews_dataset",
    "olist_customers_dataset",
    "olist_sellers_dataset",
    "olist_products_dataset",
    "olist_geolocation_dataset",
    "product_category_name_translation"
]

for table_name in tables_to_ingest:
    try:
        print(f"Extracting '{table_name}' from PostgreSQL...")
        
        df = pd.read_sql_table(table_name, con=pg_engine)
        
        bq_table_id = f"{dataset_ref}.{table_name}"
        
        job_config = bigquery.LoadJobConfig(
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            autodetect=True
        )
        
        print(f"Loading {len(df):,} rows into BigQuery -> {bq_table_id}...")
        job = bq_client.load_table_from_dataframe(df, bq_table_id, job_config=job_config)
        job.result()
        
        print(f"Successfully ingested '{table_name}'!\n" + "-" * 50)
        
    except Exception as e:
        print(f"ERROR processing '{table_name}': {e}\n" + "-" * 50)

print("INGESTION COMPLETE: All PostgreSQL tables are now live in Google BigQuery!")