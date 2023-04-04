#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Downloading istioctl $ISTIO_VERSION"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION/bin

echo "Enable Istio in default namespace"
kubectl label namespace default istio-injection=enabled

echo "Install Istio CR, IstioD, Istio Ingress and Istio Egress"
./istioctl install -f ../../traffic-management/istio-config-ingress-egress.yaml

echo "Istio Ingress Gateway configuration"
kubectl apply -f ../../traffic-management/istio-gateway-ingress.yaml

echo "Sample workload and virtual service"
kubectl apply -f ../../traffic-management/hello-world-resources.yaml

echo "Create workload for use in tests"
kubectl create deployment nginx --image=nginx

echo "Simulating the usage of Isto Gateway (ingress) calling the Service with the desired host"
kubectl exec -it deployment/nginx -- curl istio-ingressgateway.istio-system/helloworld/ip -H "Host: my-host.private"

echo "Istio Egress Gatewyay configuration + HTTPBIN egress configuration"
kubectl apply -f ../../traffic-management/istio-gateway-egress.yaml
kubectl apply -f ../../traffic-management/httpbin-egress-configuration.yaml

echo "Simulating the usage of Isto Gateway (egress) calling external service"
kubectl exec -it deployment/nginx -- curl http://httpbin.org/ip

echo "Validating that the request went through Istio Gateway (egress)"
kubectl logs deployment/istio-egressgateway -n istio-system | grep "httpbin.org" | grep "443"