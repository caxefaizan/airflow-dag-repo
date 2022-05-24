from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.sensors.python import PythonSensor
# Waits for a Python callable to return True.
from airflow.exceptions import AirflowSensorTimeout
from datetime import datetime
default_args = {
    'start_date': datetime(2022, 5, 1)
}

def _extract():
    print('Extracting Info')

def _data_engineer():
    return False

def _devops_engineer():
    return True


def _ml_engineer():
    return True

def _post():
    print("Welcome OnBoard")

def _failure_callback(context):
    if isinstance(context['exception'], AirflowSensorTimeout):
        print(context)
        print("Sensor timed out")

with DAG(
    'my_dag', 
    schedule_interval='@daily', 
    default_args=default_args, 
    catchup=False
) as dag:

    data_engineer = PythonSensor(
                    task_id='data_engineer',
                    poke_interval=5,
                    timeout=30,
                    mode="reschedule",
                    python_callable=_data_engineer,
                    on_failure_callback=_failure_callback,
                    soft_fail=True
                )

    devops_engineer = PythonSensor(
                    task_id='devops_engineer',
                    poke_interval=20,
                    timeout=10,
                    mode="reschedule",
                    python_callable=_devops_engineer,
                    on_failure_callback=_failure_callback,
                    soft_fail=True
                )

    ml_engineer = PythonSensor(
                    task_id='ml_engineer',
                    poke_interval=20,
                    timeout=10,
                    mode="reschedule",
                    python_callable=_ml_engineer,
                    on_failure_callback=_failure_callback,
                    soft_fail=True
                )

    extract =  PythonOperator(
                task_id="extract",
                python_callable=_extract,
                trigger_rule='none_failed_or_skipped'
            )

    post =  PythonOperator(
                task_id="post",
                python_callable=_post,
                trigger_rule='none_failed_or_skipped'
            )

    [data_engineer, devops_engineer, ml_engineer] >> extract >> post
