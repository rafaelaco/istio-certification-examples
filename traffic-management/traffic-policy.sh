#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Installing istioctl $ISTIO_VERSION"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION/bin

echo "Installing Istio with 'minimal' profile"
./istioctl install --set profile=minimal --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON

echo "Label default namespace to enable istio injection"
kubectl label namespace default istio-injection=enabled

echo "Installing workload for policy tests"
kubectl create deployment nginx --image=nginx
kubectl create deployment ab --image=jordi/ab
kubectl apply -f ../../traffic-management/traffic-policy-objects.yaml

# Test "http2MaxRequests": Run the following 
## TERMINAL 1 (we should see an error)
# kubectl exec -it deployment/ab -- ab -k -c 2 -n 1000 http://myapp.default.svc.cluster.local/

## TERMINAL 1 (we should see no errors)
# kubectl exec -it deployment/ab -- ab -k -c 2 -n 1000 http://myapp2.default.svc.cluster.local/

## TERMINAL 1 (we should see an error)
# kubectl exec -it deployment/ab -- ab -k -c 6 -n 1000 http://myapp2.default.svc.cluster.local/

# Test "LEAST_CONN balancing": Run the following (the first POD must have many logs and the second few)

## TERMINAL 1
# pod1=$(kubectl get pods -l app=myapp -o json | jq -r '.items[0].status.podIP')
# pod2=$(kubectl get pods -l app=myapp -o json | jq -r '.items[1].status.podIP')
# for i in {1..1000}; do kubectl exec -it deployment/nginx -- curl -Is $pod1 | grep "HTTP"; done;

## TERMINAL 2
# pod1=$(kubectl get pods -l app=myapp -o json | jq -r '.items[0].status.podIP')
# pod2=$(kubectl get pods -l app=myapp -o json | jq -r '.items[1].status.podIP')
# for i in {1..5}; do kubectl exec -it deployment/nginx -- curl -Is myapp.default.svc.cluster.local | grep "HTTP"; done;

## TERMINAL 3
# kubectl logs $(kubectl get pods -l app=myapp -o json | jq -r '.items[0].metadata.name') -c istio-proxy
# kubectl logs $(kubectl get pods -l app=myapp -o json | jq -r '.items[1].metadata.name') -c istio-proxy