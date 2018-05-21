# How to SSH into a private Kubernetes agent node

WARNING:  SSH'ing into an agent node is an [anti-pattern](https://en.wikipedia.org/wiki/Anti-pattern) and should be avoided.  However, we don't live in an ideal world, and sometimes we have to do what's necessary.

This walkthrough is designed for users managing a Kubernetes cluster who cannot readily SSH to into their agent nodes (e.g. [AKS](https://docs.microsoft.com/en-us/azure/aks/) does not publicly expose the agent nodes for security considerations).

You can follow the steps on the [SSH to AKS cluster nodes](https://docs.microsoft.com/en-us/azure/aks/aks-ssh) walkthrough; however, that requires you to upload your Private SSH key which I would rather avoid.

## Assumptions

* The SSH Public key has been installed for your user on the Agent host

## Install an SSH Server

If you're paranoid, you can generate your own SSH server container; however, [this one by Corbin Uselton](https://github.com/corbinu/ssh-server) has some pretty good security defaults and is available on Docker Hub.

```shell
kubectl run ssh-server --image=corbinu/ssh-server --port=22 --restart=Never
```

## Setup port forward

Instead of exposing a service with an IP+Port, we'll take the easy way and kubectl to port-forward to your localhost

```shell
kubectl port-forward ssh-server 2222:22
```

## Inject your Public SSH key

Since we're using the ssh-server as a jumphost, we need to inject our SSH key into the SSH Server.  Using root for simplicity's sake, but I recommend a more secure approach going forward. (TODO:  Change this to use a non-privileged user.)

```shell
cat ~/.ssh/id_rsa.pub | kubectl exec -i ssh-server -- /bin/bash -c "cat >> /root/.ssh/authorized_keys"
```

## SSH to the proxied port

Using the SSH Server as a jumphost (via port-forward proxy), ssh into the IP address of the desired host.

```shell
# Get the list of Host + IP's
kubectl get nodes -o json | jq '.items[].status.addresses[].address'
# $USER = Username on the agent host
# $IP = IP of the agent host
ssh -J root@127.0.0.1:2222 $USER@$IP
```
