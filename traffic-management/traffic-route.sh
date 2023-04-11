#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Installing istioctl $ISTIO_VERSION"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION/bin

echo "Installing Istio with 'minimal' profile"
./istioctl install --set profile=minimal --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON

echo "Label default namespace to enable istio injection"
kubectl label namespace default istio-injection=enabled

echo "Installing workload for routing tests"
kubectl create deployment nginx --image=nginx
kubectl apply -f ../../traffic-management/traffic-route-objects.yaml

echo "Updating HTML sample"
sleep 10
kubectl exec -it deployment/myapp-v1 -- /bin/bash -c 'echo "Server v1" >> /usr/share/nginx/html/index.html'
kubectl exec -it deployment/myapp-v2 -- /bin/bash -c 'echo "Server v2" >> /usr/share/nginx/html/index.html'

echo "Check server versions"
sleep 10
kubectl exec -it deployment/myapp-v1 -- curl localhost | grep "Server"
kubectl exec -it deployment/myapp-v2 -- curl localhost | grep "Server"

echo "Call the service and see the traffic being routed"
sleep 10
kubectl exec -it deployment/nginx -- /bin/bash -c 'for i in {1..6}; do curl -s http://myapp.default | grep "Server"; done;'