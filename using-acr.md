# Containers Orchestrator hands-on lab with Kubernetes

## Create Azure Container Service Repository (ACR)

In the previous step the image for ngnix was pulled from a public repository. For many customers they want to only deploy images from internal (controlled) private registries.  In this session, we will download the nginx image and upload it to ACR

### Create ACR Registry

> Note: ACR names are globally scoped so you can check the name of a registry before trying to create it

```shell
RESOURCE_GROUP=my-k8s-cluster-$USER
ACR_NAME=myacr${USER}${RANDOM}
echo ACR_NAME = $ACR_NAME
az acr check-name --name $ACR_NAME
```

Results:

```shell
{
  "message": null,
  "nameAvailable": true,
  "reason": null
}
```

The minimal parameters to create a ACR are a name, resource group and location. With these parameters a storage account will be created and administrator access will not be created.

> Note: the command will return the resource id for the registry. That id will need to be used in subsequent steps if you want to create service principals that are scoped to this registry instance.

```shell
az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP --location eastus --sku Standard
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
```

Create a two service principals, one with read only and one with read/write access.
> Note:
> 1. Ensure that the password length is 8 or more characters
> 1. The command will return an application id for each service principal. You'll need that id in subsequent steps.
> 1. You should consider using the --scope property to qualify the use of the service principal a resource group or registry

Create a reader Service Principal

```shell
READER_SP_NAME=my-acr-reader-$USER
READER_SP_PASSWD=$(az ad sp create-for-rbac --name $READER_SP_NAME --scopes $ACR_REGISTRY_ID --role reader --query password --output tsv)
echo Reader password = $READER_SP_PASSWD
READER_SP_APP_ID=$(az ad sp show --id http://$READER_SP_NAME --query appId --output tsv)
```

Create a contributor Service Principal

```shell
CONTRIBUTOR_SP_NAME=my-acr-contributor-$USER
CONTRIBUTOR_SP_PASSWD=$(az ad sp create-for-rbac --name $CONTRIBUTOR_SP_NAME --scopes $ACR_REGISTRY_ID --role contributor --query password --output tsv)
echo Contributor password = $CONTRIBUTOR_SP_PASSWD
CONTRIBUTOR_SP_APP_ID=$(az ad sp show --id http://$CONTRIBUTOR_SP_NAME --query appId --output tsv)
```

### Push demo app images to ACR

List the local docker images. You should see the images built in the initial steps when deploying the application locally.

```shell
docker pull nginx:latest
docker images nginx:latest
```

Tag the images for to associate them with you private ACR instance.

```shell
docker tag nginx:latest $ACR_NAME.azurecr.io/workshop/my-nginx:latest
```

Using the Contributor Service Principal, log into the ACR. The login command for a remote registry has the form:

```shell
docker login -u $CONTRIBUTOR_SP_APP_ID -p $CONTRIBUTOR_SP_PASSWD $ACR_NAME.azurecr.io
```

Results:

```shell
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Login Succeeded
```

### Push the image to the ACR

```shell
docker push $ACR_NAME.azurecr.io/workshop/my-nginx
```

### Verify we can pull image

```shell
docker pull $ACR_NAME.azurecr.io/workshop/my-nginx
```

### Deploy the ACR credentials to K8S

At this point the images are in ACR, but the cluster will need credentials to be able to pull and deploy the images

```shell
kubectl create secret docker-registry acr-reader --docker-server $ACR_NAME.azurecr.io --docker-username $READER_SP_APP_ID --docker-password $READER_SP_PASSWD --docker-email me@email.com
```

Results:

```shell
secret "acr-reader" created
```

## Deploy a Helm chart using the new image

```shell
helm install --set image.repository=$ACR_NAME.azurecr.io/workshop/my-nginx,image.tag=latest,image.imagePullSecrets=acr-reader ./yaml/acr-test
```

## Verify setup

```shell
HELM_RELEASE=$(helm ls -qdr | head -1)
helm status
kubectl get all
```

## Cleanup

```shell
az acr delete -n $ACR_NAME
az ad sp delete --id=$READER_SP_APP_ID
az ad sp delete --id=$CONTRIBUTOR_SP_APP_ID
kubectl delete secret acr-reader
helm delete $HELM_RELEASE
```
