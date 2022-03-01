#!/usr/bin/env bash

var=$(dpkg -s kubectl | grep Status)
if [[  $var != "Status: install ok installed" ]] 
then
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    echo "Kubectl not present. Installing now."
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl
    kubectl version --client
else
    echo "Kubectl already present"
fi

var=$(dpkg -s helm | grep Status)
if [[  $var != "Status: install ok installed" ]] 
then
    echo "Helm not present. Installing now."
    curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
    sudo apt-get install apt-transport-https --yes
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
else
    echo "Helm already present"
fi

var=$(dpkg -s minikube | grep Status)
if [[  $var != "Status: install ok installed" ]] 
then
    echo "Minikube not present. Installing now."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
    sudo dpkg -i minikube_latest_amd64.deb
else
    echo "Minikube already Present"
fi

cluster=$(minikube status | grep "not found" | awk -F "." '{print $1}' | cut -d' ' -f2-)
if [[ $cluster ==  ' Profile "minikube" not found' ]]
then
    echo "Creating Minikube Cluster"
    minikube start
fi

status=$(minikube status | grep apiserver)
if [[ $status == "apiserver: Paused" ]]
then 
    echo "Unpausing Minikube"
    minikube unpause
elif [[ $status == "apiserver: Stopped" ]]
then
    echo "Restarting Minikube"
    minikube start
elif [[ $status == "apiserver: Running" ]]
then
    echo "Minikube Running"
    echo "Checking if all pods are running"
    pods=$(kubectl get pods -n airflow | awk -F " " '{print $3}' | tail -n +2)
    if [[ $pods == "" ]]
    then 
        flag=1
    fi
    for pod in $pods
    do
        if [[ $pod != "Running" || $pods == "" ]]
        then
            break
            flag=1
        fi
    done
    if [[ $flag ]]
    then 
        helm repo add apache-airflow https://airflow.apache.org
        helm upgrade --install airflow apache-airflow/airflow -n airflow --create-namespace --debug
        web_up=$(kubectl get pods -n airflow | grep "webserver" | awk -F " " '{print $3}')
        echo "Waiting for Webserver Pod to Spin Up"
        kubectl wait --for=condition=ready pod -l component=webserver -n airflow
        echo "Webserver succesfully started."
    fi
fi
echo "All components of Airflow are running."
echo "To access the UI from the browser at http://localhost:8080, Run command kubectl port-forward svc/airflow-webserver 8080:8080 -n airflow"
