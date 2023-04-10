#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Downloading istioctl $ISTIO_VERSION"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION/bin

echo "Install Istio CRs and IstioD"
./istioctl install --set profile=minimal --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON

echo "Enable Istio in default namespace"
kubectl label namespace default istio-injection=enabled

echo "Create workload for use in tests"
kubectl create deployment nginx --image=nginx
kubectl create deployment httpbin --image=kennethreitz/httpbin
kubectl expose deployment httpbin --port=80

echo "Create requests to generate logs in istio-proxy"
sleep 10
kubectl exec -it deployment/nginx -- /bin/bash -c 'for i in {1..5}; do curl https://httpbin.org/ip; done;'

echo "Get logs and tries to identify the outbound https traffic"
sleep 2
kubectl logs deployment/nginx -c istio-proxy | grep "httpbin.org" | wc -l # will be zero
kubectl logs deployment/nginx -c istio-proxy | grep "PassthroughCluster" | wc -l # will be five

echo "Create a Service Entry"
kubectl apply -f ../../traffic-management/service-entry.yaml

echo "Create requests to generate logs in istio-proxy"
sleep 10
kubectl exec -it deployment/nginx -- /bin/bash -c 'for i in {1..5}; do curl https://httpbin.org/ip; done;'

echo "Get logs and identify the outbound https traffic now"
sleep 2
kubectl logs deployment/nginx -c istio-proxy | grep "httpbin.org" | wc -l # will be five
kubectl logs deployment/nginx -c istio-proxy | grep "PassthroughCluster" | wc -l # will be five

echo "Create a Virtual Service for the Service Entry making non-tls calls to use internal services instead of external services"
kubectl apply -f ../../traffic-management/service-entry-virtual-service.yaml

echo "Create the request to be handled by the virtual service"
kubectl exec -it deployment/nginx -- /bin/bash -c 'for i in {1..5}; do curl http://httpbin.org/ip; done;'

echo "Get logs to see that the requests are landing to the local service"
kubectl logs deployment/httpbin -c istio-proxy # requests to local service