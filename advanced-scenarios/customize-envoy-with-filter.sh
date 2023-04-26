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
kubectl apply -f ../../advanced-scenarios/envoy-filter.yaml
kubectl wait pods -l app=nginx --for condition=Ready --timeout=90s
kubectl wait pods -l app=httpbin --for condition=Ready --timeout=90s

echo "Send test for check the custom added headers"
kubectl exec -it deployment/nginx -- /bin/bash -c 'curl http://httpbin/headers' # check the request headers
kubectl exec -it deployment/nginx -- /bin/bash -c 'curl -I http://httpbin/ip' # check the response headers

echo "Cleaning"
kubectl delete -f ../../advanced-scenarios/envoy-filter.yaml