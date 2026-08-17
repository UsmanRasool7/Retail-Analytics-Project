# Olist ELT Pipeline

This repository contains an end-to-end ELT (Extract, Load, Transform) pipeline for the Olist e-commerce dataset. It integrates data ingestion, Airflow orchestration, and dbt transforms to move raw data into analytics-ready models.

## Table of contents

- Project overview
- Components
- Repository layout
- Prerequisites
- Quick start (local)
- Developing & testing
- Running dbt
- Running the Airflow DAGs
- Deployment notes
- Troubleshooting
- Contributing

## Project overview

The pipeline ingests raw source data, stages it into a data warehouse, and runs transformations with dbt to produce marts and facts for analytics. Airflow (in `astro/`) orchestrates the end-to-end flow. Key goals:

- Reliable ingestion of Olist dataset files
- Idempotent, tested dbt models
- Reproducible local development via Docker and Python virtualenvs

## Components

- Ingestion: `include/ingestion.py` - scripts to fetch, unzip, and load raw CSVs into the chosen data warehouse or local staging area.
- Orchestration: `astro/dags/` contains Airflow DAGs (`olist_pipeline.py`, `simple_pipeline.py`, `simple2.py`) and Docker setup for running task workers.
- Transformations: A dbt project under `include/dbt_project/` with models in `include/dbt_project/models/` and tests in `include/dbt_project/tests/`.
- Models: canonical models live in `models/` (marts and staging are present).
- Tests: lightweight SQL-based tests under `tests/` and dbt tests under the dbt project.

## Repository layout (important files)

- `include/ingestion.py` - ingestion utility
- `astro/Dockerfile` - Docker image used for Airflow / workers
- `astro/dags/` - DAG definitions
- `include/dbt_project/` - dbt project (models, macros, profiles)
- `tests/` - SQL tests for core assertions

## Prerequisites

- Python 3.9+ (3.10 recommended)
- pip
- git
- Docker (for running Airflow in containers)
- dbt-core and the appropriate dbt adapter for your data warehouse (e.g. `dbt-postgres`, `dbt-bigquery`, `dbt-snowflake`) or use the `dbt` included in the `include/dbt_project` environment

Optional tools:

- Airflow or Astronomer CLI if you want to run the `astro` container locally

## Configuration & environment variables

Create a `.env` file or export environment variables for runtime/configuration. Typical variables used by the project:

- `DBT_PROFILES_DIR` - path to `profiles.yml` for dbt (defaults to `include/dbt_project/`)
- `DATA_WAREHOUSE_URL` or `DATABASE_URL` - SQLAlchemy-compatible connection URL for ingestion and tests
- `AIRFLOW__CORE__SQL_ALCHEMY_CONN` - Airflow metadata DB connection (for containerized Airflow)
- `AIRFLOW__CORE__FERNET_KEY` - Airflow Fernet key (if running production-like Airflow)

Example `.env` (adjust for your environment):

```bash
DBT_PROFILES_DIR=include/dbt_project
DATABASE_URL=postgresql://user:password@localhost:5432/olist
AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql://airflow:airflow@localhost:5432/airflow
AIRFLOW__CORE__FERNET_KEY=YOUR_FERNET_KEY
```

## Quick start (local development)

1. Clone the repo and change into the project directory:

```bash
git clone <repo-url>
cd olist_proj
```

2. Create and activate a Python virtual environment, then install dependencies:

```bash
python -m venv .venv
source .venv/Scripts/activate   # Windows: .venv\Scripts\activate
pip install --upgrade pip
pip install -r astro/requirements.txt
```

3. Create and populate the database used for local development (example uses Postgres). Ensure `DATABASE_URL` points to your DB.

4. Run ingestion to fetch files and load staging tables. Adjust CLI flags or env vars as needed:

```bash
python ingestion.py
```

5. Run dbt transforms (see "Running dbt" below).

6. Optionally run Airflow locally to orchestrate the full pipeline (see "Running the Airflow DAGs").

## Running dbt

The dbt project is in `include/dbt_project/`. Basic dbt commands:

```bash
cd include/dbt_project
# install deps if you use packages
dbt deps

# Run models
dbt run --profiles-dir . --project-dir .

# Run tests
dbt test --profiles-dir . --project-dir .

# Compile and inspect compiled models
dbt compile --profiles-dir . --project-dir .
```

Notes:

- Edit `include/dbt_project/profiles.yml` to point to your local data warehouse. A `profiles.yml` is already present for reference.
- If you use a different adapter (BigQuery, Snowflake, etc.), install the correct `dbt-<adapter>` package in your environment and update `profiles.yml`.

## Running the Airflow DAGs

Airflow DAGs live in `astro/dags/`. There are a few ways to run them:

1. Containerized via Dockerfile in `astro/` (recommended for parity with CI):

```bash
cd astro
docker build -t olist-astro:local .
# Start container (example, adjust ports/env as needed)
docker run --env-file ../.env -p 8080:8080 olist-astro:local
```

2. Use an Airflow local environment (e.g., `docker-compose` with official Airflow images) and mount `astro/dags` into the scheduler and worker containers.

3. Run DAGs directly with the Airflow CLI (when Airflow is installed in your venv):

```bash
export AIRFLOW_HOME=$(pwd)/astro/airflow_home
airflow db init
airflow users create --username admin --firstname Admin --lastname User --role Admin --email admin@example.com
airflow webserver --port 8080
airflow scheduler
```

Open the Airflow UI at http://localhost:8080 and trigger `olist_pipeline` or the relevant DAG.

## Tests & CI

- dbt tests: run with `dbt test` in `include/dbt_project`.
- Python-based DAG/unit tests: see `tests/dags/test_dag_example.py` for examples using `pytest`.

Run Python tests:

```bash
pytest -q
```

## Debugging & Troubleshooting

- If dbt fails to connect, verify `profiles.yml` and `DBT_PROFILES_DIR`.
- If Airflow DAGs don't appear, ensure your DAG folder is mounted and `AIRFLOW__CORE__DAGS_FOLDER` points to `astro/dags`.
- If ingestion errors occur, check `DATABASE_URL` and confirm tables/schemas exist or modify the ingestion script to create them.

Logs:

- Check `logs/` for local logs created by dbt/ingestion.
- Check Airflow UI logs per task instance for detailed tracebacks.

## Contributing

Contributions are welcome. Please follow these steps:

1. Open an issue describing the change.
2. Create a feature branch.
3. Add tests for new functionality.
4. Open a pull request and tag reviewers.


