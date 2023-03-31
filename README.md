# istio-certification-examples
This repository has examples and materials regarding the Istio Certification (Tetrate). As the exam uses the Istio 1.13.1 version, all the examples will be using this version.

## Istio Installation, Upgrade & Configuration
Examples of how to:
 - Use IstioOperator to install a basic cluster
 - Use IstioOperator to customize and configure Istio components installation
 - Use overlays to customize Istio component settings

It's important to note that when you use `istioctl` you are installing using the "IstioOperator" CR, because of that you can use any supported parameters from the "IstioOperator API".

References:
 - [Installation Guide](https://istio.io/v1.13/docs/setup/install/istioctl/)
 - [IstioOperator API](https://istio.io/v1.13/docs/reference/config/istio.operator.v1alpha1/)

## How to use this project
You need a kubernetes cluster running and configured in your context.

Then, just run the scripts in the root folder, example:

```console
./install-upgrade-configure/overlay-istiooperator-install.sh
```