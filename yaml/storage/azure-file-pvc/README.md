
Tips and tricks for later
```
kubectl get pods -l app=azure-volume-file -o json | jq '.items[0].spec.nodeName' -r
```
