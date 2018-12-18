# Setup: Run once, for each VM if SSH keys are not already setup
az vm user update --resource-group $RG --name $VM --username $USER --ssh-key-value ~/.ssh/id_rsa.pub

kubectl run ssh-server --image=corbinu/ssh-server --port=22 --restart=Never
kubectl port-forward ssh-server 2222:22 &
cat ~/.ssh/id_rsa.pub | kubectl exec -i ssh-server -- /bin/bash -c "cat >> /root/.ssh/authorized_keys"
IP=$(kubectl get nodes -o json | jq '.items[0].status.addresses[0].address' -r)

ssh -J root@127.0.0.1:2222 $USER@$IP
