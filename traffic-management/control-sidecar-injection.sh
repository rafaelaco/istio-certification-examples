#!/bin/bash
ISTIO_OLD_VERSION="1.12.4"
ISTIO_NEW_VERSION="1.13.1"

echo "Installing two versions of Istio ($ISTIO_OLD_VERSION and $ISTIO_VERSION)"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_OLD_VERSION sh -
cd istio-$ISTIO_OLD_VERSION/bin
./istioctl install --set profile=minimal --set revision=1-12-4

cd ../../
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_NEW_VERSION sh -
cd istio-$ISTIO_NEW_VERSION/bin
./istioctl analyze
./istioctl install --set profile=minimal --set revision=1-13-1

echo "Enable sidecar in a Istio enabled namespace"
kubectl create namespace sidecar-ns
kubectl label namespace sidecar-ns istio-injection=enabled
kubectl run istio-pod --image=nginx --namespace=sidecar-ns

echo "Disable sidecar in a Istio enabled namespace"
kubectl run non-istio-pod --image=nginx --namespace=sidecar-ns --labels="sidecar.istio.io/inject=false"

echo "Enable sidecar in a non-istio namespace for only one POD"
kubectl create namespace non-istio
kubectl run non-istio-pod --image=nginx --namespace=non-istio
kubectl run istio-pod --image=nginx --namespace=non-istio --labels="sidecar.istio.io/inject=true"

echo "Enable specific revision (1-13-1) sidecar for namespace"
kubectl create namespace revision-ns
kubectl label namespace revision-ns istio.io/rev=1-13-1
kubectl run revision-pod --image=nginx --namespace=revision-ns

echo "Enable specific revision (1-13-1) sidecar for pod in a non-revision namespace"
kubectl create namespace non-revision-ns
kubectl run revision-pod --image=nginx --namespace=non-revision-ns --labels="istio.io/rev=1-13-1"

echo "Showing the Istio tags"
./istioctl tag list

echo "Showing versions used by sidecars"
sleep 10
./istioctl proxy-status

echo "Calling from one pod to any hosts with no issues"
kubectl expose pod istio-pod --port=80 --name=istio-pod --namespace=sidecar-ns
kubectl expose pod revision-pod --port=80 --name=revision-pod --namespace=revision-ns
kubectl exec -it istio-pod --namespace=sidecar-ns -- curl http://revision-pod.revision-ns
kubectl exec -it revision-pod --namespace=revision-ns -- curl http://istio-pod.sidecar-ns
kubectl exec -it revision-pod --namespace=revision-ns -- curl https://httpbin.org/ip

echo "Deploying the Sidecar resource to block some outbounds"
kubectl apply -f ../../traffic-management/sidecar.yaml --namespace=revision-ns

echo "Being blocked when try to call unknown services"
kubectl exec -it revision-pod --namespace=revision-ns -- curl http://istio-pod.sidecar-ns
kubectl exec -it revision-pod --namespace=revision-ns -- curl https://httpbin.org/ip # will return an error