from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator


default_args = {
    "owner": "data-engineering",
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
}


with DAG(
    dag_id="retail_analytics_pipeline",
    default_args=default_args,
    description="Postgres to BigQuery ELT pipeline",
    start_date=datetime(2026, 8, 12),
    schedule="@daily",
    catchup=False,
    tags=["retail", "elt", "dbt"],
) as dag:

    ingest = BashOperator(
        task_id="ingest",
        bash_command=(
            "python /usr/local/airflow/include/ingest_to_bq.py"
        ),
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=(
            "cd /usr/local/airflow/include/retail_analytics_project "
            "&& dbt run "
            "--profiles-dir /usr/local/airflow/include/dbt_profiles"
        ),
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=(
            "cd /usr/local/airflow/include/retail_analytics_project "
            "&& dbt test "
            "--profiles-dir /usr/local/airflow/include/dbt_profiles"
        ),
    )

    ingest >> dbt_run >> dbt_test