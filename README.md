# istio-certification-examples
This repository has examples and materials regarding the Istio Certification (Tetrate). As the exam uses the Istio 1.13.1 version, all the examples will be using this version.

## Istio Installation, Upgrade & Configuration
Examples of how to:
 - Use IstioOperator to install a basic cluster
 - Use IstioOperator to customize and configure Istio components installation
 - Use overlays to customize Istio component settings
 - Use canary upgrade of Istio components

It's important to note that when you use `istioctl` you are installing using the "IstioOperator" CR, because of that you can use any supported parameters from the "IstioOperator API".

References:
 - [Installation Guide](https://istio.io/v1.13/docs/setup/install/istioctl/)
 - [IstioOperator API](https://istio.io/v1.13/docs/reference/config/istio.operator.v1alpha1/)

## Traffic Management
Examples of how to:
 - Understand and control sidecar injection and configuration using Sidecar resource
 - Use Gateway resource to configure ingress and egress gateways
 - Understand how to use ServiceEntry resource for adding entries to internal service registry
 - Understand traffic routing and how to configure routing between difference service versions
 - Define traffic policies using DestinationRule
 - Configure traffic mirroring capabilities

## Resiliency and Fault Injection
Examples of how to:
 - Understand and configure outlier detection
 - Use resiliency features
 - Configure failure injection

## Securing Workloads
Examples of how to:
 - Set up Istio authorization for HTTP/TCP traffic in the mesh
 - Configure mutual TLS on mesh, namespace, and workload level

## Advanced Scenarios
Examples of how to:
 - Onboard non-Kubernetes workloads to the mesh
 - Customize Envoy configuration using Envoy Filters

## How to use this project
You need a kubernetes cluster running and configured in your context.

Then, just run the scripts in the root folder, example:

```console
./install-upgrade-configure/overlay-istiooperator-install.sh
```