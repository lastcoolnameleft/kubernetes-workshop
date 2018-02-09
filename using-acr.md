# Containers Orchestrator hands-on lab with Kubernetes

## Create Azure Container Service Repository (ACR)

In the previous step the image for ngnix was pulled from a public repository. For many customers they want to only deploy images from internal (controlled) private registries.  In this session, we will download the nginx image and upload it to ACR

### Create ACR Registry

> Note: ACR names are globally scoped so you can check the name of a registry before trying to create it

```shell
RESOURCE_GROUP=my-k8s-cluster-$USER
ACR_NAME=myacr${USER}
az acr check-name --name $ACR_NAME
```

The minimal parameters to create a ACR are a name, resource group and location. With these parameters a storage account will be created and administrator access will not be created.

> Note: the command will return the resource id for the registry. That id will need to be used in subsequent steps if you want to create service principals that are scoped to this registry instance.

```shell
az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP --location eastus --sku Standard
```

Create a two service principals, one with read only and one with read/write access.
> Note:
> 1. Ensure that the password length is 8 or more characters
> 1. The command will return an application id for each service principal. You'll need that id in subsequent steps.
> 1. You should consider using the --scope property to qualify the use of the service principal a resource group or registry

```shell
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
READER_SP_NAME=my-acr-reader-$USER
READER_SP_PASSWD=$(az ad sp create-for-rbac --name $READER_SP_NAME --scopes $ACR_REGISTRY_ID --role reader --query password --output tsv)
READER_SP_APP_ID=$(az ad sp show --id http://$READER_SP_NAME --query appId --output tsv)

CONTRIBUTOR_SP_NAME=my-acr-contributor-$USER
CONTRIBUTOR_SP_PASSWD=$(az ad sp create-for-rbac --name $CONTRIBUTOR_SP_NAME --scopes $ACR_REGISTRY_ID --role contributor --query password --output tsv)
CONTRIBUTOR_SP_APP_ID=$(az ad sp show --id http://$CONTRIBUTOR_SP_NAME --query appId --output tsv)
```

### Push demo app images to ACR

List the local docker images. You should see the images built in the initial steps when deploying the application locally.

```shell
docker pull hello-world:latest
docker images hello-world:latest
```

Tag the images for service-a and service-b to associate them with you private ACR instance.
> Note that you must provide your ACR registry endpoint

```shell
docker tag hello-world:latest $ACR_NAME.azurecr.io/my-hello-world:latest
```

Using the Contributor Service Principal, log into the ACR. The login command for a remote registry has the form: 

```shell
docker login -u $CONTRIBUTOR_SP_APP_ID -p $CONTRIBUTOR_SP_PASSWD $ACR_NAME.azurecr.io
```

### Push the images

```shell
docker push $ACR_NAME.azurecr.io/my-hello-world
```

At this point the images are in ACR, but the k8 cluster will need credentials to be able to pull and deploy the images

### Create a k8 docker-repository secret to enable read-only access to ACR

```shell
kubectl create secret docker-registry acr-reader --docker-server=$ACR_NAME.azurecr.io --docker-username=$CONTRIBUTOR_SP_APP_ID --docker-password=$CONTRIBUTOR_SP_PASSWD --docker-email=me@email.com
```

### Create k8s-demo-app.yml 

Make the changes to point to your ACR instance

https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/k8s-demo-app.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-container-demo
  labels:
    name: multi-container-demo
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
  selector:
    app: multi-container-demo
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: multi-container-demo
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: multi-container-demo
    spec:
      containers:
        - name: web
          image: myacr.azurecr.io/service-a
          env:
            - 
              name: LISTENPORT
              value: "8080"
            -  
              name: BACKEND_HOSTPORT
              value: 'localhost:80'
            -  
              name: REDIS_HOST
              value: localhost
          ports:
            - containerPort: 8080
        - name: api
          image: myacr.azurecr.io/service-b
          ports:
            - containerPort: 80
        - name: mycache
          image: redis
          ports:
            - containerPort: 6379
      imagePullSecrets:
        - name: acr-reader
```


### Deploy the application to the k8 cluster

Review the contents of the k8-demo-app.yml file. It contains the objects to be created on the k8 cluster.
 - Note that multiple objects can be included within the same file
 - Note the environment variables that are used to configure endpoints. 
 - Since these containers are being deployed to a Pod:
    - The containers will communicate via localhost. 
    - Containers cannot listen on the same port

Update the image references in the k8-demo-app.yml file to reference your ACR endpoint

```yaml
    spec:
      containers:
        - name: web
          image: <myk8acr-microsoft.azurecr.io>/service-a
          ...
        - name: api
          image: <myk8acr-microsoft.azurecr.io>/service-b
          ...
        - name: mycache
```

Deploy the application using the kubectl create command:

```shell
wget https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/k8s-demo-app.yaml
sed "s/myacr.azurecr.io/$ACR_NAME.azurecr.io/g" < k8s-demo-app.yaml > k8s-demo-app-update.yaml
kubectl create -f ./k8s-demo-app-update.yaml
```

If you run `kubectl get pods,svc,deploy`, you should see something like:

```shell
NAME                                      READY     STATUS              RESTARTS   AGE
po/multi-container-demo-604940585-1c7wn   0/3       ContainerCreating   0          59s
po/nginx-2371676037-6b718                 1/1       Running             0          39m
po/nginx-deployment-3285060500-1rrrd      1/1       Running             0          40m
po/nginx-deployment-3285060500-rsm70      1/1       Running             0          40m
po/nginx2                                 1/1       Running             0          42m
po/redis-nginx                            2/2       Running             0          43m

NAME                       CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
svc/kubernetes             10.0.0.1      <none>          443/TCP        58m
svc/multi-container-demo   10.0.43.186   <pending>       80:31495/TCP   1m
svc/nginx                  10.0.245.66   13.65.214.240   80:30577/TCP   39m

NAME                          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/multi-container-demo   1         1         1            0           59s
deploy/nginx                  1         1         1            1           39m
deploy/nginx-deployment       2         2         2            2           42m
```

## Cleanup

```shell
az ad sp delete --id=$READER_SP_APP_ID
az ad sp delete --id=$CONTRIBUTOR_SP_APP_ID
```

## Next Steps

1. [Lab Overview](README.md)
1. [Create AKS Cluster](create-aks-cluster.md)
1. [Hello-world on Kubernetes](k8s-hello-world.md)
1. [Experimenting with Kubernetes Features](k8s-features.md)
1. [Create Azure Container Service Repository (ACR)](using-acr.md)
1. [Enable OMS monitoring of containers](oms.md)
1. [Create and deploy into Kubernetes Namspaces](k8s-namespaces.md)
