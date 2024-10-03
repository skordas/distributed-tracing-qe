#!/bin/bash

# Variables used in generate-traces job
num_of_workers=3
num_of_traces_per_second=300 #Number of traces for the first test.
num_of_child_spans=50
generation_time=60 # Time to generate traces
num_of_traces=$(($num_of_traces_per_second*$generation_time))
increase_number=100
decrease_number=10

wait=10 #in seconds
retries=10 # number of retries

failure_num_of_tps=0 # Store number after last failure.
succes_after_failure_num_of_tps=0

# function get_some_code {
#   git clone https://github.com/openshift/distributed-tracing-qe.git
#   cd distributed-tracing-qe
#   cd tests/perfscale-sizing-recommendation
# }
#

function get_some_code {
  git clone https://github.com/skordas/distributed-tracing-qe.git
  cd distributed-tracing-qe
  git checkout metrics-update 
  cd tests/perfscale-sizing-recommendation
}

function create_job_file {
cat > $job_file  <<- EOM
apiVersion: batch/v1
kind: Job
metadata:
  name: generate-traces
  namespace: test-generate-traces
spec:
  completions: ${num_of_workers}
  parallelism: ${num_of_workers}
  template:
    spec:
      nodeSelector:
        node-role.kubernetes.io/worker: ""
      containers:
      - name: loadgen
        image: ghcr.io/honeycombio/loadgen/loadgen:latest
        args:
        - --dataset=loadtest
        - --tps=${num_of_traces_per_second}
        - --depth=${num_of_child_spans}
        - --nspans=${num_of_child_spans}
        - --runtime=${generation_time}s
        - --ramptime=1s
        - --tracecount=${num_of_traces}
        - --protocol=grpc
        - --sender=otel
        - --host=tempo-tempostack-distributor.test-perfscale:4317
        - --loglevel=info
        - --insecure
      restartPolicy: Never
  backoffLimit: 4
EOM
}

function get_ingester_traces_created {
  metrics=$(bash check_metrics.sh)
  traces_created=$(echo $metrics | cut -d " " -f 3)
  accepted_spans=$(echo $metrics | cut -d " " -f 6)
  rejected_spans=$(echo $metrics | cut -d " " -f 9)
  echo $traces_created $accepted_spans $rejected_spans
}


## START HERE ###

get_some_code

while [[ $failure_num_of_tps -eq 0 ]] || [[ $succes_after_failure_num_of_tps -eq 0 ]]; do
  try=1
  echo ""
  echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
  echo "Number of workers                    : $num_of_workers"
  echo "Numer of traces generated/sec/node   : $num_of_traces_per_second"
  echo "Number of child spans per trace      : $num_of_child_spans"
  echo "Run time                             : $generation_time"
  echo "Number of generated traces/node      : $num_of_traces"
  echo "Number to increase number of traces  : $increase_number"
  echo "Number to decrease number of traces  : $decrease_number"
  echo "Wait seconds time before retries     : $wait"
  echo "Number of retries                    : $retries"
  echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
  bash 00-before_test.sh small

  job_file="/tmp/job_$(date +%Y%m%d%H%M%S).yaml"
  create_job_file
  bat $job_file
  oc create -f $job_file

  echo "------ lets observe metrics before start checking ------"
  for i in $(seq 1 $(($generation_time/$wait+1))); do
    sleep $wait
    bash check_metrics.sh
    echo ""
  done

  exp_num_of_traces=$(($num_of_workers*$num_of_traces))
  exp_num_of_spans=$(($num_of_workers*$num_of_traces*$num_of_child_spans))
  exp_num_of_rej_spans=0
  echo ""
  echo "=============================================="
  echo "Expected number of traces:         $exp_num_of_traces"
  echo "Expected number of spans:          $exp_num_of_spans"
  echo "Expected number of rejected spans: $exp_num_of_rej_spans"
  echo "=============================================="

  while :; do
    echo "Checking current ingested number of traces. Try $try/$retries"
    sleep $wait
    read curr_traces curr_spans curr_rej_spans < <(get_ingester_traces_created)
    echo "================================================"
    echo $curr_traces $curr_spans $curr_rej_spans
    echo "================================================"
    if [[ $curr_traces -ge $exp_num_of_traces ]] && [[ $curr_spans -ge $exp_num_of_traces ]] && [[ $curr_rej_spans -le $exp_num_of_rej_spans ]]; then
      echo "OK - lets increase the number of traces"
      if [[ $failure_num_of_tps -gt 0 ]]; then
        succes_after_failure_num_of_tps=$num_of_traces_per_second
      fi
      num_of_traces_per_second=$(($num_of_traces_per_second+$increase_number))
      num_of_traces=$(($num_of_traces_per_second*$generation_time))
      break
    else
      if [[ $try -ge $retries ]]; then
        echo "NOT OK - I need to deacrease number of traces"
        failure_num_of_tps=$num_of_traces_per_second
        num_of_traces_per_second=$((num_of_traces_per_second-$decrease_number))
        num_of_traces=$(($num_of_traces_per_second*$generation_time))
        break
      fi
      try=$(($try+1))
    fi
  done

  # some Extra checking

  echo "------------------------------------------------------"
  echo "Checking job: oc describe job generate-traces -n test-generate-traces"
  oc describe job generate-traces -n test-generate-traces
  echo ""

  echo "------------------------------------------------------"
  echo "Checking pods created by job"
  for p in $(oc get pods -n test-generate-traces --no-headers | cut -d ' ' -f 1); do
    echo $p
    oc logs $p -n test-generate-traces
    echo ""
  done

  bash 02-after_test_cleaning.sh

  ### TODO !!! ####
  echo "sleep..... Remove me!!!!!!"
  echo "change bat to cat"
  echo ""
  echo ""
  echo ""
  sleep 5
  ### TODO
  # Check the test with different number of spans - maybe then we will get nicer number of traces.
  # end test when after first going down nmumbers need to get up!
  # BETTER - store MAXIMUM - then if maximum is already higher then run again with maximum - but previous is already higher. ignore for the first incrementation - with first decrementation setup flag
  # Now maybe - MAX variable - store after success. when failure - store max failure
done

echo "DONE!!!!"
echo "The lowest failure: $failure_num_of_tps"
echo "The highest after failure: $succes_after_failure_num_of_tps"
