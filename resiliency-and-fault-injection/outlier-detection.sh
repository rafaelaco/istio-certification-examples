#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Installing istioctl $ISTIO_VERSION"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION/bin

echo "Install istio with minimal profile"
./istioctl install --set profile=minimal --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON

echo "Enable Istio"
kubectl label namespace default istio-injection=enabled

echo "Creating workloads for testing"
kubectl apply -f ../../resiliency-and-fault-injection/outlier-detection.yaml
kubectl create deployment nginx --image=nginx
kubectl wait pods -l app=httpbin --for condition=Ready --timeout=90s
kubectl wait pods -l app=nginx --for condition=Ready --timeout=90s

echo "Making request for trigger outlier detection"

echo "Successful request"; 
kubectl exec -it deployment/nginx -- curl http://httpbin.default.svc.cluster.local/ip

echo -e "\nCircuit breaker blocking the request"; 
kubectl exec -it deployment/nginx -- /bin/bash -c 'for i in {1..10}; do curl http://httpbin.default.svc.cluster.local/status/503; done;'
kubectl exec -it deployment/nginx -- curl http://httpbin.default.svc.cluster.local/ip

echo -e "\nCircuit breaker stop blocking after some seconds"
sleep 20
kubectl exec -it deployment/nginx -- curl http://httpbin.default.svc.cluster.local/ip

echo -e "\nCleaning"
kubectl delete deployment nginx
kubectl delete -f ../../resiliency-and-fault-injection/outlier-detection.yaml