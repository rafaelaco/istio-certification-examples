#!/bin/bash
ISTIO_OLD_VERSION="1.12.4"
ISTIO_NEW_VERSION="1.13.1"

######### OLD VERSION
echo "Downloading istioctl ${ISTIO_OLD_VERSION}"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_OLD_VERSION sh -

echo "Installing Istio CRs version $ISTIO_OLD_VERSION"
cd istio-$ISTIO_OLD_VERSION/bin
./istioctl install --set profile=empty --set components.base.enabled=true --set revision="1-12-4"

echo "Installing Istio Control Plane $ISTIO_OLD_VERSION"
./istioctl install --set profile=empty --set components.pilot.enabled=true --set revision="1-12-4"

echo "Enabling Istio in the 'canary' namespace"
kubectl create namespace canary
kubectl label namespace canary istio.io/rev=1-12-4

echo "Creating sample deployment in 'canary' namespace"
kubectl create deployment nginx --image=nginx -n canary

echo "Enabling Istio in the 'release' namespace"
kubectl create namespace release
kubectl label namespace release istio.io/rev=1-12-4

echo "Creating sample deployment in 'release' namespace"
kubectl create deployment nginx --image=nginx -n release

######### NEW VERSION
cd ../../
echo "Downloading istioctl ${ISTIO_NEW_VERSION}"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_NEW_VERSION sh -

echo "Check if we can install the version $ISTIO_NEW_VERSION"
cd istio-$ISTIO_NEW_VERSION/bin
./istioctl x precheck
./istioctl analyze

echo "Installing Istio CRs version $ISTIO_NEW_VERSION"
./istioctl install --set profile=empty --set components.base.enabled=true --set revision="1-13-1"

echo "Installing Istio Control Plane $ISTIO_NEW_VERSION"
./istioctl install --set profile=empty --set components.pilot.enabled=true --set revision="1-13-1"

#### Commands to simulate an upgrade
## Running the commands below you see the deployment changing the Istio Version
## We will also have two control planes in the cluster
####

# kubectl get deployments -n istio-system
# istioctl proxy-status
# kubectl label namespace canary istio.io/rev=1-13-1 --overwrite
# kubectl rollout restart deployment/nginx -n canary
# istioctl proxy-status