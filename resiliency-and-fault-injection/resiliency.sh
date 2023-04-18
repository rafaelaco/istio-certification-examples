#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Installing istioctl $ISTIO_VERSION"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION/bin

echo "Installing istio with minimal profiel"
./istioctl install --set profile=minimal --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON

echo "Enable istio on default namespace"
kubectl label namespace default istio-injection=enabled

echo "Creating workloads for testing"
kubectl apply -f ../../resiliency-and-fault-injection/resiliency.yaml
kubectl create deployment nginx --image=nginx
kubectl wait pods -l app=httpbin --for condition=Ready --timeout=90s
kubectl wait pods -l app=nginx --for condition=Ready --timeout=90s

echo "Making request for trigger retry"
kubectl exec -it deployment/nginx -- curl -X GET -I http://httpbin.default.svc.cluster.local/status/503

echo -e "\nChecking logs to see the multiple attempts"
sleep 5
kubectl logs deploy/httpbin -c istio-proxy | grep "/status/503" | wc -l #it should return 4

echo -e "\nMaking request for trigger timeout"
kubectl exec -it deployment/nginx -- curl -X GET -I http://httpbin.default.svc.cluster.local/delay/5
sleep 5
kubectl logs deploy/nginx -c istio-proxy | grep -w "UT" # we received the response-flag=UT (upstream request timeout)

echo -e "\nCleaning"
kubectl delete deployment nginx
kubectl delete -f ../../resiliency-and-fault-injection/resiliency.yaml