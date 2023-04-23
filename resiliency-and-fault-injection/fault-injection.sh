#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Install istioctl $ISTIO_VERSION"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION/bin

echo "Install istio in minimal profile"
./istioctl install --set profile=minimal --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON

echo "Enable istio in default namespace"
kubectl label namespace default istio-injection=enabled

echo "Creating workloads for testing"
kubectl apply -f ../../resiliency-and-fault-injection/fault-injection.yaml
kubectl create deployment nginx --image=nginx
kubectl wait pods -l app=httpbin --for condition=Ready --timeout=90s
kubectl wait pods -l app=nginx --for condition=Ready --timeout=90s

echo -e "\nCreating requests to show the errors and delays added"
kubectl exec -it deployment/nginx -- /bin/bash -c 'for i in {1..10}; do echo ""; time curl -Is httpbin/ip | grep -E "HTTP"; done;'

echo -e "\nCleaning"
kubectl delete deployment nginx
kubectl delete -f ../../resiliency-and-fault-injection/fault-injection.yaml