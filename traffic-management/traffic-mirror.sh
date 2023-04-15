#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Installing istioctl $ISTIO_VERSION"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION/bin

echo "Installing Istio in minimal profile"
./istioctl install --set profile=minimal --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON

echo "Make default namespace Istio enabled"
kubectl label namespace default istio-injection=enabled

echo "Deploy workloads to test the mirroring"
kubectl apply -f ../../traffic-management/traffic-mirror.yaml

echo "Wait for pod be ready"
kubectl wait pods -l app=nginx --for condition=Ready --timeout=90s
kubectl wait pods -l app=httpbin --for condition=Ready --timeout=90s

echo "Sending requests to test mirroring"
kubectl exec -it deployment/nginx -- curl http://httpbin.default/headers

echo "Get logs to validate"

echo -e "\nHTTPBIN logs"
kubectl logs deployment/httpbin1 -c istio-proxy | grep "/headers"

echo -e "\nNGINX mirrored requests logs"
kubectl logs deployment/nginx -c nginx | grep "/headers"

echo -e "\nRemove resources"
kubectl delete -f ../../traffic-management/traffic-mirror.yaml