# Fill these in
SUBSCRIPTION_ID=
# az ad sp create-for-rbac --skip-assignment
SERVICE_PRINCIPAL=
SERVICE_PRINCIPAL_PASSWORD=

RESOURCE_BASE=aks-1-11
VNET_RESOURCE_GROUP=$RESOURCE_BASE-vnet-rg
VNET_NAME=$RESOURCE_BASE-vnet
VNET_ADDRESS_PREFIX=10.0.0.0/16
VNET_SUBNET_PREFIX=10.0.0.0/22
SUBNET_NAME=$RESOURCE_BASE-subnet
VNET_SUBNET_ID=/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$VNET_RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$SUBNET_NAME

LOCATION=centralus
AKS_RESOURCE_NAME=$RESOURCE_BASE-aks
AKS_RESOURCE_GROUP=$AKS_RESOURCE_NAME-rg
ADMIN_USERNAME=$USER
KUBERNETES_VERSION=1.11.2
AKS_NETWORK_PLUGIN=azure
DNS_NAME_PREFIX=$AKS_RESOURCE_NAME
AKS_NODE_COUNT=2
AKS_NODE_VM_SIZE=Standard_DS2_v2
AKS_POD_CIDR=$VNET_SUBNET_PREFIX
AKS_MAX_PODS=20

AKS_SERVICE_CIDR=10.1.0.0/24          # Must be outside of Vnet Address space
AKS_DNS_SERVICE_IP=10.1.0.5           # Must be inside the AKS Service CIDR
AKS_DOCKER_BRIDGE_ADDRESS=172.17.0.1/16  # Must be outside of the Vnet Address space

az group create -n $VNET_RESOURCE_GROUP -l $LOCATION
az network vnet create -g $VNET_RESOURCE_GROUP -n $VNET_NAME --address-prefix $VNET_ADDRESS_PREFIX
az network vnet subnet create -g $VNET_RESOURCE_GROUP --vnet-name $VNET_NAME --address-prefix $VNET_ADDRESS_PREFIX -n $SUBNET_NAME

az group create -n $AKS_RESOURCE_GROUP -l $LOCATION
az aks create --resource-group $AKS_RESOURCE_GROUP --name $AKS_RESOURCE_GROUP --location $LOCATION --max-pods $AKS_MAX_PODS --admin-username $ADMIN_USERNAME --kubernetes-version $KUBERNETES_VERSION --network-plugin $AKS_NETWORK_PLUGIN --dns-name-prefix $DNS_NAME_PREFIX --node-count $AKS_NODE_COUNT --node-vm-size $AKS_NODE_VM_SIZE --vnet-subnet-id $VNET_SUBNET_ID --service-cidr $AKS_SERVICE_CIDR --dns-service-ip $AKS_DNS_SERVICE_IP --docker-bridge-address $AKS_DOCKER_BRIDGE_ADDRESS --enable-addons 'http_application_routing' --ssh-key-value ~/.ssh/id_rsa.pub --service-principal=$SERVICE_PRINCIPAL --client-secret=$SERVICE_PRINCIPAL_PASSWORD
az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_RESOURCE_GROUP

# Cleanup
kubectl config delete-cluster $AKS_RESOURCE_GROUP
kubectl config delete-context $AKS_RESOURCE_GROUP
kubectl config unset users.clusterUser_${AKS_RESOURCE_GROUP}_${AKS_RESOURCE_GROUP}
az group delete -n MC_${AKS_RESOURCE_GROUP}_${AKS_RESOURCE_GROUP}_${LOCATION} -y
az group delete -n $VNET_RESOURCE_GROUP -y
az group delete -n $AKS_RESOURCE_GROUP -y
