# Containers Orchestrator hands-on lab with Kubernetes
## Create Azure Container Service Repository (ACR)

In the previous step the image for ngnix was pulled from a public repository. For many customers they want to only deploy images from internal (controlled) private registries.

### Create ACR Registry
> Note: ACR names are globally scoped so you can check the name of a registry before trying to create it
```
ACR_NAME=myacr
az acr check-name --name $ACR_NAME
```

The minimal parameters to create a ACR are a name, resource group and location. With these parameters a storage account will be created and administrator access will not be created.

> Note: the command will return the resource id for the registry. That id will need to be used in subsequent steps if you want to create service principals that are scoped to this registry instance.

```
az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP --location eastus --sku Managed_Standard
```

Create a two service principals, one with read only and one with read/write access.
> Note:
> 1. Ensure that the password length is 8 or more characters
> 1. The command will return an application id for each service principal. You'll need that id in subsequent steps.
> 1. You should consider using the --scope property to qualify the use of the service principal a resource group or registry

```
az ad sp create-for-rbac --name my-acr-reader --role Reader --password my-acr-password
az ad sp create-for-rbac --name my-acr-contributor  --role Contributor --password my-acr-password
```

### Push demo app images to ACR

*NOTE: This needs to be done on the same machine you built your docker images*

List the local docker images. You should see the images built in the initial steps when deploying the application locally.

```
docker images
```

Tag the images for service-a and service-b to associate them with you private ACR instance.
> Note that you must provide your ACR registry endpoint

```
docker tag service-a:latest $ACR_NAME.azurecr.io/service-a:latest
docker tag service-b:latest $ACR_NAME.azurecr.io/service-b:latest
```

Using the Contributor Service Principal, log into the ACR. The login command for a remote registry has the form: 
```
docker login -u <ContributorAppId>  -p my-acr-password $ACR_NAME.azurecr.io
```

### Push the images
```
docker push $ACR_NAME.azurecr.io/service-a
docker push $ACR_NAME.azurecr.io/service-b
```

At this point the images are in ACR, but the k8 cluster will need credentials to be able to pull and deploy the images

### Create a k8 docker-repository secret to enable read-only access to ACR
```
kubectl create secret docker-registry acr-reader --docker-server=$ACR_NAME.azurecr.io --docker-username=<service-principal-app-id> --docker-password=<my-acr-password> --docker-email=<your-email>
```

### Create k8s-demo-app.yml 
Make the changes to point to your ACR instance

https://github.com/lastcoolnameleft/workshops/blob/master/kubernetes/yaml/k8s-demo-app.yaml

```
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
```
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
```
wget https://raw.githubusercontent.com/lastcoolnameleft/workshops/master/kubernetes/yaml/k8s-demo-app.yaml
sed "s/myacr.azurecr.io/$ACR_NAME.azurecr.io/g" < k8s-demo-app.yaml > k8s-demo-app-update.yaml
kubectl create -f ./k8s-demo-app-update.yaml
```

If you run `kubectl get pods,svc,deploy`, you should see something like:
```
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

## Lab Navigation
1. [Lab Overview](./index.md)
1. [Kubernetes Installation on Azure](./step01.md)
1. [Hello-world on Kubernetes](./step02.md)
1. [Experimenting with Kubernetes Features](./step03.md)
    1. Placement
    1. Reconciliation
    1. Rolling Updates
1. [Deploying a Pod and Service from a public repository](./step04.md)
1. [Create Azure Container Service Repository (ACR)](./step05.md) *<-- You are here*
1. [Enable OMS monitoring of containers](./step06.md)
1. [Create and deploy into Kubernetes Namspaces](./step07.md)

[Back to Index](../../index.md)
