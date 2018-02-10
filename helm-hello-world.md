# Helm Hello World

## Prerequisite

* [Install Helm](helm-install.md)

## See a list of Helm charts

The list of stable Helm charts are [here](https://github.com/kubernetes/charts/tree/master/stable).  You can also view all of the charts registered with your CLI by running:

```shell
helm repo update
helm search
```

## Deploy a MySQL Helm Chart

Each helm chart deployed will creates a release name.  We will install a MySQL Helm chart

```shell
helm install --set persistence.storageClass=default stable/mysql
```

As it's being deployed, you can view the status through the `helm status` command.

```shell
HELM_RELEASE=$(helm ls -qdr | head -1)
helm status $HELM_RELEASE
kubectl get all
```

## Cleanup

To cleanup, you only need to delete the release.

```shell
helm delete $HELM_RELEASE
```
