#!/bin/bash

# TODO
# Add exit after repeats
# Check not only is pod is running also is it ready

set -o errexit
set -o pipefail

sleep_time=30
r=10 # Nmuber of repeats

function log_task {
  echo -e "\n------====== $1 ======------"
}

### NAMESPACE ###
log_task "CREATING NAMESPACE"
oc create -f ./content/01-01-namespace.yaml

for i in $(seq $r)
do
  status=$(oc get namespace test-perfscale -o jsonpath={.status.phase})
  echo "Try #$i/$r Status of namespace: $status"
  if [[ $status == "Active" ]]
  then
    echo "Namespace test-perfscale is ready"
    break
  else
    echo "Namespace test-perfscale is not ready. Waiting for next $sleep_time seconds"
    sleep $sleep_time
  fi
done

### PREPARE STORAGE ###
log_task "Persistent Volume Claim"
oc create -f ./content/02-01-persistentvolumeclaim.yaml
log_task "Create Deployments"
oc create -f ./content/02-02-deployment.yaml
log_task "Create Service"
oc create -f ./content/02-03-service.yaml
log_task "Create secret"
oc create -f ./content/02-04-secret.yaml

for i in $(seq $r)
do
  status_pvc=$(oc get pvc minio -n test-perfscale -o jsonpath={.status.phase})
  status_dep=$(oc get deployment minio -n test-perfscale -o jsonpath={.status.availableReplicas})
  status_pod=$(oc get pods -n test-perfscale -l app.kubernetes.io/name=minio -o jsonpath={.items[0].status.phase})
  echo "Try #$i/$r Status of:"
  echo "  Persistent Volume Claim: $status_pvc"
  echo "  Deployment:              $status_dep"
  echo "  Pod:                     $status_pod"
  if [[ $status_pvc == "Bound" ]] && [[ $status_dep == "1" ]] && [[ $status_pod == "Running" ]]
  then
    echo "Storage is ready"
    break
  else
    echo "Storage is not ready. Waiting for next $sleep_time seconds"
    sleep $sleep_time
  fi
done

### WORKLOAD MONITORING ###
log_task "Workload Monitoring"
oc create -f ./content/03-01-workload-monitoring.yaml

for i in $(seq $r)
do
  name=$(oc get configmap cluster-monitoring-config -n openshift-monitoring -o jsonpath={.metadata.name})
  echo "Try #$i/$r name of new configmap: $name"
  if [[ $name == "cluster-monitoring-config" ]]
  then
    echo "Configmap cluster-monitoring-config is ready"
    break
  else
    echo "Configmap cluster-monitoring-config is not ready. Wating for next $sleep_time seconds"
    sleep $sleep_time
  fi
done


### PREPARE TEMPOSTACK ###
log_task "TempoStack"
oc create -f ./content/04-01-tempostack.yaml
sleep 5

for i in $(seq $r)
do
  status_compactor=$(oc get pods -n test-perfscale -l app.kubernetes.io/component=compactor -o jsonpath={.items[0].status.phase})
  status_distributor=$(oc get pods -n test-perfscale -l app.kubernetes.io/component=distributor -o jsonpath={.items[0].status.phase})
  status_ingester=$(oc get pods -n test-perfscale -l app.kubernetes.io/component=ingester -o jsonpath={.items[0].status.phase})
  status_querier=$(oc get pods -n test-perfscale -l app.kubernetes.io/component=querier -o jsonpath={.items[0].status.phase})
  status_frontend=$(oc get pods -n test-perfscale -l app.kubernetes.io/component=query-frontend -o jsonpath={.items[0].status.phase})
  echo "Try #$i/$r Status of:"
  echo "  Compactor pod:   $status_compactor"
  echo "  Distributor pod: $status_distributor"
  echo "  Ingester pod:    $status_ingester"
  echo "  Querier pod:     $status_querier"
  echo "  Frontend pod:    $status_frontend"
  if [[ $status_compactor == "Running" ]] && [[ $status_distributor == "Running" ]] && [[ $status_ingester == "Running" ]] && [[ $status_querier == "Running" ]] && [[ $status_frontend == "Running" ]]
  then
    echo "TempoStack is ready"
    break
  else
    echo "TempoStack is not ready. Waiting for next $sleep_time seconds"
    sleep $sleep_time
  fi
done

### PREPARE CLUSTERROLEBINDING ###
log_task "ClusterRoleBinding"
oc create -f ./content/05-01-clusterrolebinding.yaml

