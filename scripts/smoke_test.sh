#!/bin/bash
KUBECTL="kubectl --kubeconfig=kubeconfig"

$KUBECTL create deploy echoserver --image=jmalloc/echo-server --replicas=10
# sleep 30
[ $($KUBECTL get pod -owide -o custom-columns=NAME:.metadata.name,IP:.status.podIP | tail -n+2 | grep 10.244 | wc -l) == "10"  ] \
    && echo "Correct pod cidr" || echo "Incorrect cidr (or using Weave)"
$KUBECTL expose deploy echoserver --port=8080
$KUBECTL expose deploy echoserver --name=echoserver-nodeport --type=NodePort --port=8080
$KUBECTL run -i --rm curl --image=curlimages/curl --restart=Never -- curl -s http://echoserver:8080
NODEPORT=$($KUBECTL get svc echoserver-nodeport -ojsonpath='{.spec.ports[0].nodePort}')
NODE=$($KUBECTL get nodes -ojsonpath='{.items[?(@.metadata.name=="worker-0")].status.addresses[0].address}')
ssh -fNT -L 12348:$NODE:$NODEPORT admin@$BASTION
curl http://127.0.0.1:12348
