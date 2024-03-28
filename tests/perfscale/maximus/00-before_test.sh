#!/bin/bash

set -o errexit
set -o pipefail

#
### SETUP WORKLOAD MONITORING ###
# 01 enable monitoring
#
### SETUP TEMPOSTACK ####
# 01 TempoStack
#

## TODO

sleep_time=30
r=10

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

