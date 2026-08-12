from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator


def task_a():
    print("Task A: Starting pipeline")


def task_b():
    print("Task B: Processing data")


def task_c():
    print("Task C: Pipeline completed successfully")


with DAG(
    dag_id="simple_pipeline",
    start_date=datetime(2026, 8, 12),
    schedule="0 9 * * *",
    catchup=False,
    default_args={
        "retries": 2,
        "retry_delay": timedelta(seconds=10),
    },
) as dag:

    task_a = PythonOperator(
        task_id="task_a",
        python_callable=task_a,
    )

    task_b = PythonOperator(
        task_id="task_b",
        python_callable=task_b,
    )

    task_c = PythonOperator(
        task_id="task_c",
        python_callable=task_c,
    )

    task_a >> task_b >> task_c