# Containers Orchestrator hands-on lab with Kubernetes

## Enable OMS monitoring of containers

This expands on the steps described in the following documentation:

* <https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-monitor>
* <https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-containers>
* <https://hub.kubeapps.com/charts/stable/msoms>

## Steps

* Go to the Azure portal and create a new "Log Analytics" resource.
* Get the workspace id and a key (see the page referenced in the prior link).

Deploy the agent with the following command:

```shell
WORKSPACE_ID=
LA_KEY=
helm install --name omsagent --set omsagent.secret.wsid=$WORKSPACE_ID,omsagent.secret.key=$LA_KEY stable/msoms
```

If this is a new Log Analytics cluster, it will take a long time (~30 minutes to initialize) and for the logs to propagate.
