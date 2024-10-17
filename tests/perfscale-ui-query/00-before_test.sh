#!/bin/bash

function log_task {
  echo -e "\n------====== $1 ======------"
}

### NAMESPACE ###
log_task "CREATING NAMESPACE"
oc create -f ./content/01-namespace.yaml


