from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator


def task_one():
    print("Task 1: Starting pipeline")


def task_two():
    print("Task 2: Processing data")
    raise Exception("Intentional failure for retry testing")


def task_three():
    print("Task 3: Pipeline completed")


default_args = {
    "retries": 2,
    "retry_delay": timedelta(minutes=1),
}


with DAG(
    dag_id="hello_pipeline",
    start_date=datetime(2026, 8, 12),
    schedule="@daily",
    catchup=False,
    default_args=default_args,
    tags=["training"],
) as dag:

    task_1 = PythonOperator(
        task_id="task_one",
        python_callable=task_one,
    )

    task_2 = PythonOperator(
        task_id="task_two",
        python_callable=task_two,
    )

    task_3 = PythonOperator(
        task_id="task_three",
        python_callable=task_three,
    )

    task_1 >> task_2 >> task_3