# Ingress and Ingress Controller

In short, ingress resources are ways of defining traffic routing inside Kubernetes.  The routes are managed by the Ingress resource and implemented by the Ingress Controller resource (e.g. <https://github.com/kubernetes/ingress-nginx>).

For details, on the Kubernetes Ingress resource, see: <https://kubernetes.io/docs/concepts/services-networking/ingress/#what-is-ingress>

## AKS Cluster

If you are using an AKS cluster and created it with "HTTP Application Routing" enabled, then congratulations, you already have an Ingress Controller installed!  You do not need to follow these instructions.

You can see the custom Ingress Controller by running `kubectl get svc addon-http-application-routing-nginx-ingress -n kube-system`

For details, see: https://docs.microsoft.com/en-us/azure/aks/http-application-routing

## Install Nginx Ingress Controller

Before installing the ingress resource, we should create the ingress controller, which will implement the routes.  For our example, we will use the nginx-ingress helm chart.

```shell
INGRESS_CONTROLLER_RELEASE_NAME=${INGRESS_CONTROLLER_RELEASE_NAME=nginx-ingress}
INGRESS_CONTROLLER_NAMESPACE=${INGRESS_CONTROLLER_NAMESPACE=default}
helm install --name $INGRESS_CONTROLLER_RELEASE_NAME --namespace $INGRESS_CONTROLLER_NAMESPACE stable/nginx-ingress
# or if using RBAC
helm install --name $INGRESS_CONTROLLER_RELEASE_NAME --namespace $INGRESS_CONTROLLER_NAMESPACE --set rbac.create=true stable/nginx-ingress

```

## Validation

```shell
INGRESS_CONTROLLER_NAMESPACE=${INGRESS_CONTROLLER_NAMESPACE=default}
INGRESS_CONTROLLER_IP=$(kubectl get service nginx-ingress-controller -n $INGRESS_CONTROLLER_NAMESPACE -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
until [ $INGRESS_CONTROLLER_IP ]
do
    INGRESS_CONTROLLER_IP=$(kubectl get service nginx-ingress-controller -n $INGRESS_CONTROLLER_NAMESPACE -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    sleep 5
done
echo $INGRESS_CONTROLLER_IP
kubectl get service nginx-ingress-controller -n $INGRESS_CONTROLLER_NAMESPACE
```

Results:

```shell
NAME                                      TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                      AGE
nginx-ingress-nginx-ingress-controller    LoadBalancer   10.0.200.229   13.85.82.216   80:32063/TCP,443:31520/TCP   1d
```

## Cleanup

To cleanup, remove the ingress controller

```shell
INGRESS_CONTROLLER_RELEASE_NAME=${INGRESS_CONTROLLER_RELEASE_NAME=nginx-ingress}
helm delete --purge $INGRESS_CONTROLLER_RELEASE_NAME
```
