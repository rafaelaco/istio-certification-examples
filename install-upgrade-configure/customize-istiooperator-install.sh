#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Download istioctl ${ISTIO_VERSION}"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

echo "Installing Istio CR"
cd istio-${ISTIO_VERSION}/bin
./istioctl install --set profile=empty --set components.base.enabled=true

echo "Installing Istio Control Plane using custom revision"
./istioctl install --set profile=empty --set components.pilot.enabled=true --set revision=1-13-1

echo "Enabling Istio in the 'custom' namespace"
kubectl create namespace custom
kubectl label namespace custom istio-injection=enabled