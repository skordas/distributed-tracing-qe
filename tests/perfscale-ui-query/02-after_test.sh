#!/bin/bash

function log_task {
  echo -e "\n------====== $1 ======------"
}

log_task "Cleaning after test"

oc project default

oc delete project test-perfscale
oc delete project test-generate-traces
