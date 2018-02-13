# Prometheus and Grafana

> NOTE:  Untested with SimDem

Used as a starting point:
<https://medium.com/@timfpark/simple-kubernetes-cluster-monitoring-with-prometheus-and-grafana-dd27edb1641>

## Install Prometheus

```shell
HELM_PROMETHEUS=prometheus
helm install --name $HELM_PROMETHEUS stable/prometheus
```

## Install Grafana

```shell
HELM_GRAFANA=grafana
helm install --name grafana stable/grafana
```

## Install Nginx Ingress Controller

```shell
HELM_NGINX_INGRESS_NAME=nginx-ingress
helm install --name $HELM_NGINX_INGRESS_NAME stable/nginx-ingress
SERVICE_IP='null'
until [ $SERVICE_IP != 'null' ]; do SERVICE_IP=$(kubectl get service $HELM_NGINX_INGRESS_NAME-nginx-ingress-controller -o json | jq '.status.loadBalancer.ingress[0].ip' -r || unset SERVICE_IP) || sleep 5; done
echo $SERVICE_IP
```

## Install Ingress Rules

Modify the existing yaml/ingress.template.yaml to replace the following

* HELM_PROMETHEUS
* HELM_GRAFANA
* SERVICE_IP

```shell
kubectl apply -f yaml/ingress.yaml
```