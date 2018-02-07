# Cleanup

## Delete Cluster Resource Group

```shell
RESOURCE_GROUP=my-k8s-cluster-$USER
az group delete --name $RESOURCE_GROUP -y
```
