# Containers Orchestrator hands-on lab with Kubernetes

## Hello-world on Kubernetes

From the [Kubernetes Quick Start](http://kubernetes.io/docs/user-guide/quick-start/)

### To run a simple app on Kubernetes, we can use: `kubectl run`

Let us start by running a simple HTTP server: nginx. Nginix is a popular HTTP server, with a pre-built container on Docker hub. The kubectl run commands below will create two nginx replicas, listening on port 80, and a public IP address for your application.

```shell
kubectl run my-nginx --image=nginx --replicas=2 --port=80
```

Results:

```shell
deployment "my-nginx" created
```

### To expose your service to the public internet, use

```shell
kubectl expose deployment my-nginx --target-port=80 --type=LoadBalancer
```

Results:

```shell
service "my-nginx" exposed
```

### You can see that they are running by

Kubernetes will ensure that your application keeps running, by automatically restarting containers that fail, spreading containers across nodes, and recreating containers on new nodes when nodes fail.

### Get the Public IP Address

When you first try to get the Service IP, the External Public IP will not show up yet.  This is because it is still being provisioned from Azure.

```shell
kubectl get service my-nginx
```

Results:

```shell
NAME       TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
my-nginx   LoadBalancer   10.0.206.82   <pending>     80:32226/TCP   2m
```

Keep running the `kubectl get service` command, until the LoadBalancer IP is datafilled:

```shell
SERVICE_IP='null'
until [ $SERVICE_IP != 'null' ]; do SERVICE_IP=$(kubectl get service my-nginx -o json | jq '.status.loadBalancer.ingress[0].ip' -r || unset SERVICE_IP) || sleep 5; done
echo $SERVICE_IP
kubectl get service my-nginx
```

Results:

```output
NAME       TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
my-nginx   LoadBalancer   10.0.206.82   52.151.63.4   80:32226/TCP   3m
```

Once the external-ip is available, we can proceed:

```shell
curl $SERVICE_IP
```

Results:

```shell
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

### Cleanup

To kill the application and delete its containers and public IP address

```shell
kubectl delete deployment,service my-nginx
```

Results:

```shell
deployment "my-nginx" deleted
service "my-nginx" deleted
```
