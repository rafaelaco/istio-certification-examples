#!/bin/bash
ISTIO_VERSION="1.13.1"
NO_PERMISSION_TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg"
CORRECT_TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjM1MzczOTExMDQsImdyb3VwcyI6WyJncm91cDEiLCJncm91cDIiXSwiaWF0IjoxNTM3MzkxMTA0LCJpc3MiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyIsInNjb3BlIjpbInNjb3BlMSIsInNjb3BlMiJdLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.EdJnEZSH6X8hcyEii7c8H5lnhgjB5dwo07M5oheC8Xz8mOllyg--AHCFWHybM48reunF--oGaG6IXVngCEpVF0_P5DwsUoBgpPmK1JOaKN6_pe9sh0ZwTtdgK_RP01PuI7kUdbOTlkuUi2AO-qUyOm7Art2POzo36DLQlUXv8Ad7NBOqfQaKjE9ndaPWT7aexUsBHxmgiGbz1SyLH879f7uHYPbPKlpHU6P9S-DaKnGLaEchnoKnov7ajhrEhGXAQRukhDPKUHO9L30oPIr5IJllEQfHYtt6IZvlNUGeLUcif3wpry1R5tBXRicx2sXMQ7LyuDremDbcNy_iE76Upg"

echo "Installing istioctl $ISTIO_VERSION"
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cd istio-$ISTIO_VERSION/bin

echo "Installing istio with minimal profile"
./istioctl install --set profile=minimal --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON

echo "Enable istio on default namespace"
kubectl label namespace default istio-injection=enabled

echo "Creating workloads for testing service-to-service auth (mTLS)"
kubectl apply -f ../../securing-workloads/peer-auth.yaml

# Namespace PERMISSIVE test resources
kubectl create deployment httpbin --image=kennethreitz/httpbin -n test
kubectl expose deployment httpbin --port=80 -n test

kubectl create deployment nginx --image=nginx -n test
kubectl patch deployment nginx -p '{"spec": {"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"false"}}}} }' -n test
kubectl rollout restart nginx -n test

# Namespace STRICT test resources
kubectl create deployment httpbin --image=kennethreitz/httpbin -n default
kubectl expose deployment httpbin --port=80 -n default

kubectl create deployment nginx --image=nginx -n default
kubectl patch deployment nginx -p '{"spec": {"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"false"}}}} }' -n default
kubectl rollout restart deployment nginx -n default

# Namespace PERMISSIVE test resources
kubectl create deployment httpbin2 --image=kennethreitz/httpbin -n default
kubectl expose deployment httpbin2 --port=80 -n default

# Waiting services
kubectl wait pods -l app=httpbin --for condition=Ready --timeout=90s -n test
kubectl wait pods -l app=nginx --for condition=Ready --timeout=90s -n test
kubectl wait pods -l app=httpbin --for condition=Ready --timeout=90s -n default
kubectl wait pods -l app=nginx --for condition=Ready --timeout=90s -n default
kubectl wait pods -l app=httpbin2 --for condition=Ready --timeout=90s -n default

# Running tests
kubectl exec -it deployment/nginx -n default -- curl -I httpbin/ip # should return error because of the default strict rules
kubectl exec -it deployment/nginx -n test -- curl -I httpbin/ip # should be successful because of the namespace permissive
kubectl exec -it deployment/nginx -n default -- curl -I httpbin2/ip # should be successful because of the workload permissive rule

kubectl delete deployments --all
kubectl delete services --all
kubectl delete -f ../../securing-workloads/peer-auth.yaml

echo "Creating workloads for testing end-user auth (JWT)"
kubectl apply -f ../../securing-workloads/request-auth.yaml

kubectl wait pods -l app=httpbin --for condition=Ready --timeout=90s -n test
kubectl wait pods -l app=nginx --for condition=Ready --timeout=90s -n test

kubectl exec -it deployment/nginx -n test -- curl -X GET -I httpbin/ip # will receive "Forbidden"
kubectl exec -it deployment/nginx -n test -- curl -X GET -I httpbin/ip -H "Authorization: Bearer $NO_PERMISSION_TOKEN" # will receive "Forbidden"
kubectl exec -it deployment/nginx -n test -- curl -X GET -I httpbin/ip -H "Authorization: Bearer $CORRECT_TOKEN" # will receive "OK"
kubectl exec -it deployment/nginx -n test -- curl -X POST -I httpbin/post -H "Authorization: Bearer $CORRECT_TOKEN" # will receive "Forbidden"

kubectl delete -f ../../securing-workloads/request-auth.yaml