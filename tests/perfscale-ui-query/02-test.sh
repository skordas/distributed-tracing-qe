
gateway=$(oc get routes -n test-perfscale -o jsonpath={.items[0].spec.host})
echo $gateway

query="https://$gateway/api/traces/v1/dev/api/traces?end=1729707269246000&limit=20&lookback=1h&maxDuration&minDuration&service=loadset&start=1729703669246000"
echo $query
# token=$(oc create token dev-collector -n test-perfscale)
# token=$(oc create token tempo-simplest -n test-perfscale)
token=$(oc create token tempo-simplest-gateway -n test-perfscale)

curl -s -k -H "Authorization: Bearer $token" -H "Content-type: application/json" "$query"
