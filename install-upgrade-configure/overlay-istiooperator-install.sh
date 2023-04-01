#!/bin/bash
ISTIO_VERSION="1.13.1"

echo "Downloading istioctl ${ISTIO_VERSION}"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

echo "Installing IstioOperator using overlays in a custom file"
cd istio-$ISTIO_VERSION/bin
./istioctl install -f ../../install-upgrade-configure/overlay-file.yaml

echo "Enabling Istio in the 'overlay' namespace"
kubectl create namespace overlay
kubectl label namespace overlay istio-injection=enabled