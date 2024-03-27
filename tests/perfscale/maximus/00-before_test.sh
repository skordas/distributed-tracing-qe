#!/bin/bash

### INSTALL STORAGE ###
# 01 namespace
# verification 
# oc get namespace test-perfscale -o jsonpath={.status.phase}
# 02 persistent Volume Claim
# 03 deploments
# 04 service
# 05 secret
#
#
### SETUP WORKLOAD MONITORING ###
# 01 enable monitoring
#
### SETUP TEMPOSTACK ####
# 01 TempoStack
#

## TODO
# - set sets

sleep_time=30
retry=5

### NAMESPACE ###
oc create -f ./content/01-01-namespace.yaml

status=$(oc get namespace test-perfscale -o jsonpath={.status.phase})
echo "Status: right now: $status"
