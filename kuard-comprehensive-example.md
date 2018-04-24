# Kubernetes Up and Running Daemon - Complex example

## Create the PVC

```shell
kubectl apply -f comprehensive/pvc.yaml
```

## Create the ConfigMap (File)

```shell
kubectl create configmap kuard-config-file --from-file=comprehensive/kuard-config.json
kubectl describe configmap kuard-config-file
```

## Create the ConfigMap (EnvVar)

```shell
kubectl apply -f comprehensive/configmap-env.yaml
```

## Create the Secret

```shell
kubectl create secret generic kuard-secret --from-file=comprehensive/kuard-secret.json
kubectl describe secret kuard-secret
```

## Create the Deployment

```shell
kubectl apply -f comprehensive/deployment.yaml
```

## Create the Service

```shell
kubectl apply -f comprehensive/service.yaml
```

## Cleanup

```shell
kubectl delete service/kuard pvc/kuard configmap/kuard-config-env configmap/kuard-config-file secret/kuard-secret
```