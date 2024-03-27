#!/bin/bash

oc project default
oc delete job generate-traces verify-traces verify-traces-traceql -n test-perfscale
oc delete clusterrolebinding chainsaw-tempo-monitoring-view
oc delete tempostack tempostack -n test-perfscale
oc delete configmaps cluster-monitoring-config -n openshift-monitoring
oc delete secret minio-secret -n test-perfscale
oc delete service minio -n test-perfscale
oc delete deployment minio -n test-perfscale
oc delete pvc minio -n test-perfscale
oc delete project test-perfscale
