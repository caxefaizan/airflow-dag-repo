import pendulum
import sys
from airflow import DAG
from airflow.decorators import task
from airflow.operators.bash import BashOperator


with DAG(
    'py_virtual_env_2', 
    schedule_interval=None, 
    start_date=pendulum.datetime(2022, 10, 10, tz="UTC"), 
    catchup=False, tags=['pythonvirtualenv']) as dag:


    @task(task_id="print_the_context")
    def print_context(ds=None, **kwargs):
        """Print the Airflow context and ds variable from the context."""
        print(kwargs)
        print(ds)
        print(sys.version)
        return 'Whatever you return gets printed in the logs'

    @task.external_python(task_id="external_python", python='/home/astro/.pyenv/versions/my_special_virtual_env/bin/python')
    def callable_external_python(vars):
        import subprocess
        import os
        cmd = "dbt"
        args = "--version"
        temp = subprocess.Popen([cmd, args], stdout = subprocess.PIPE)
        output = str(temp.communicate())
        print(output)
        print(vars)
        print(sys.version)
        return 'A complex dependency generated value'

    @task(task_id="get_value")
    def whats_in_3_7(val):
        print(val)

    task_start = print_context()
    task_external_python = callable_external_python(task_start)
    task_end = whats_in_3_7(task_external_python)
