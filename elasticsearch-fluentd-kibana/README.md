# Log monitoring with Elasticsearch + Kibana

> NOTE: Currently a work in progress

The ELK (Elasticsearch, Logstash, Kibana) stack by Elastic is a very popular OSS solution for managing logs from VM's.

* Elasticsearch - stores and indexes logs
* Logstash - routes logs to Elasticsearch
* Kibana - visualizes logs

In the Kubernetes world, Fluentd has gained popularity, creating the EFK stack.

This walkthrough is designed to get EFK stack running on your Kubernetes cluster.  Instead of exposing each services via load balancer, we will instead use K8S ingress/ingress controller.

## Prerequisites

* Install the [Ingress Controller](../ingress/README.md)

## Install ElasticSearch

The helm repo for elasticsearch is the quickest and easiest way to get started.  This will install Elasticsearch 5.x.

```shell
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
ELASTICSEARCH_RELEASE_NAME=${ELASTICSEARCH_RELEASE_NAME=prometheus}
helm install --name $ELASTICSEARCH_RELEASE_NAME incubator/elasticsearch
```

## Install Fluentd

Fluentd runs as a daemon set and needs to be configured to speak to the newly created Elasticsearch service.

```shell
kubectl create -f yaml/fluentd-daemonset-elasticsearch.yaml
```

## Install Kibana

Kibana needs to be kept in lock-step with Elasticsearch, so this will install v5.4.3 of Kibana.  It also needs to be configured to connect to the newly created Elasticsearch service.

```shell
KIBANA_RELEASE_NAME=kibana
helm install --name $KIBANA_RELEASE_NAME --set env.ELASTICSEARCH_URL=http://$ELASTICSEARCH_RELEASE_NAME-elasticsearch-client:9200,image.tag=5.4.3,image.repository=kibana,service.internalPort=5601,service.externalPort=5601 stable/kibana
```

## Install the ingress resource

Install the ingress resource to route all traffic to the new services.  Modify the existing yaml/elasticsearch.template.yaml to replace the following:

* HELM_PROMETHEUS
* HELM_GRAFANA
* SERVICE_IP

```shell
kubectl create -f ingress/elasticsearch.yaml
```

## Check the service

The Elasticsearch and Kibana endpoints are behind the Ingress/Ingress controller.  You can find them at these URLs:

```shell
echo http://elasticsearch.$INGRESS_CONTROLLER_IP.xip.io/
echo http://kibana.$INGRESS_CONTROLLER_IP.xip.io/
```

## Cleanup

```shell
helm del --purge ELASTICSEARCH_RELEASE_NAME
helm del --purge KIBANA_RELEASE_NAME
```