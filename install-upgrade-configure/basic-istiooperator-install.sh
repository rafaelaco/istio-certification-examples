#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Downloading istioctl with version ${ISTIO_VERSION}"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -

echo "Running istioctl install"
cd istio-$ISTIO_VERSION/bin
./istioctl version
./istioctl install --set profile=minimal
./istioctl verify-install

echo "Enabling Istio in the 'basic' namespace"
kubectl create namespace basic
kubectl label namespace basic istio-injection=enabled