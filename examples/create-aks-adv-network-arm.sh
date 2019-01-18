# From https://github.com/Azure/azure-quickstart-templates/tree/master/101-aks-advanced-networking

# Fill these in
SUBSCRIPTION_ID=

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

az ad sp create-for-rbac -n "$RESOURCE_BASE" --skip-assignment
SERVICE_PRINCIPAL_CLIENT_ID=<result from the az ad sp create>
SERVICE_PRINCIPAL_PASSWORD=<result from the az ad sp create>

SERVICE_PRINCIPAL_OBJECT_ID=$(az ad sp show --id $SERVICE_PRINCIPAL_CLIENT_ID -o json | jq -r '.objectId')

az group create -n $VNET_RESOURCE_GROUP -l $LOCATION
az network vnet create -g $VNET_RESOURCE_GROUP -n $VNET_NAME --address-prefix $VNET_ADDRESS_PREFIX
az network vnet subnet create -g $VNET_RESOURCE_GROUP --vnet-name $VNET_NAME --address-prefix $VNET_ADDRESS_PREFIX -n $SUBNET_NAME

az group deployment create -g $AKS_RESOURCE_GROUP --template-uri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-aks-advanced-networking/azuredeploy.json" --parameters resourceName=$AKS_RESOURCE_NAME dnsPrefix=$DNS_NAME_PREFIX existingServicePrincipalObjectId=$SERVICE_PRINCIPAL_OBJECT_ID existingServicePrincipalClientId=$SERVICE_PRINCIPAL_CLIENT_ID existingServicePrincipalClientSecret=$SERVICE_PRINCIPAL_PASSWORD existingVirtualNetworkName=$VNET_NAME existingVirtualNetworkResourceGroup=$VNET_RESOURCE_GROUP existingSubnetName=$SUBNET_NAME serviceCidr=$AKS_SERVICE_CIDR dnsServiceIP=$AKS_DNS_SERVICE_IP dockerBridgeCidr=$AKS_DOCKER_BRIDGE_ADDRESS
