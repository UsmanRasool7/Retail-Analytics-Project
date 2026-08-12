from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator


default_args = {
    "owner": "rehan",
    "retries": 2,
    "retry_delay": timedelta(minutes=1),
}


with DAG(
    dag_id="olist_elt_pipeline",
    default_args=default_args,
    description="Olist PostgreSQL to BigQuery ELT pipeline",
    start_date=datetime(2026, 8, 12),
    schedule="@daily",
    catchup=False,
    tags=["olist", "elt", "dbt"],
) as dag:

    ingest = BashOperator(
        task_id="ingest",
        bash_command="python /usr/local/airflow/include/ingestion.py",
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=(
            "dbt run "
            "--project-dir /usr/local/airflow/include/dbt_project "
            "--profiles-dir /usr/local/airflow/include/dbt_project"
        ),
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=(
            "dbt test "
            "--project-dir /usr/local/airflow/include/dbt_project "
            "--profiles-dir /usr/local/airflow/include/dbt_project"
        ),
    )

    ingest >> dbt_run >> dbt_test