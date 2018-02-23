# Prometheus and Grafana

Used as a starting point:
<https://medium.com/@timfpark/simple-kubernetes-cluster-monitoring-with-prometheus-and-grafana-dd27edb1641>

## Prerequisites

* Install the [Ingress Controller](../ingress/README.md)

## Install Prometheus

```shell
INGRESS_CONTROLLER_NAMESPACE=${INGRESS_CONTROLLER_NAMESPACE=monitoring}
PROMETHEUS_RELEASE_NAME=${PROMETHEUS_RELEASE_NAME=prometheus}
helm install --name $PROMETHEUS_RELEASE_NAME --namespace $INGRESS_CONTROLLER_NAMESPACE stable/prometheus
```

## Install Grafana

```shell
GRAFANA_RELEASE_NAME=${GRAFANA_RELEASE_NAME=grafana}
helm install --name $GRAFANA_RELEASE_NAME --namespace $INGRESS_CONTROLLER_NAMESPACE stable/grafana
```

## Install Ingress Rules

Modify the existing yaml/prometheus.template.yaml to replace the following

* HELM_PROMETHEUS
* HELM_GRAFANA
* INGRESS_CONTROLLER_IP

```shell
cp yaml/ingress.template.yaml yaml/ingress.yaml
sed -i "s/INGRESS_CONTROLLER_IP/$INGRESS_CONTROLLER_IP/g" yaml/ingress.yaml
sed -i "s/PROMETHEUS_RELEASE_NAME/$PROMETHEUS_RELEASE_NAME/g" yaml/ingress.yaml
sed -i "s/GRAFANA_RELEASE_NAME/$GRAFANA_RELEASE_NAME/g" yaml/ingress.yaml
kubectl apply -f yaml/ingress.yaml
```

## Cleanup

```shell
helm del --purge $PROMETHEUS_RELEASE_NAME
helm del --purge $PROMETHEUS_INGRESS_RELEASE_NAME
helm del --purge $GRAFANA_RELEASE_NAME
kubectl delete -f yaml/ingress.yaml
```
