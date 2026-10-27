#!/usr/bin/env bash
# Optional paid lab. No cloud commands run until the explicit flag is supplied.
set -euo pipefail
[[ "${1:-}" == --create-billable-resources ]] || { echo 'Read docs/AZURE.md first. Requires --create-billable-resources.' >&2; exit 2; }
: "${AZURE_SUBSCRIPTION_ID:?Set subscription ID}"
: "${RESOURCE_GROUP:?Use a new dedicated resource group}"
: "${ACR_NAME:?Set globally unique lowercase alphanumeric registry name}"
: "${API_ALLOWED_CIDR:?Your current public IPv4/32; never 0.0.0.0/0}"
location="${LOCATION:-centralindia}"
cluster="${AKS_NAME:-sentinel-aks}"
python3 - "$API_ALLOWED_CIDR" "$ACR_NAME" <<'CHECK'
import ipaddress, re, sys
network = ipaddress.ip_network(sys.argv[1], strict=True)
if network.version != 4 or network.prefixlen != 32 or not network.network_address.is_global:
    raise SystemExit('API_ALLOWED_CIDR must be one public IPv4 /32')
if not re.fullmatch(r'[a-z0-9]{5,50}', sys.argv[2]):
    raise SystemExit('ACR_NAME must be 5-50 lowercase letters/digits')
CHECK
az account show >/dev/null
[[ "$(az account show --query id -o tsv)" == "$AZURE_SUBSCRIPTION_ID" ]] || { echo 'Subscription mismatch: select it deliberately with az account set' >&2; exit 2; }
[[ "$(az group exists --name "$RESOURCE_GROUP")" == false ]] || { echo 'Refusing an existing resource group. Inspect it before retrying.' >&2; exit 2; }
az group create --name "$RESOURCE_GROUP" --location "$location" --tags project=cloudops-sentinel purpose=learning >/dev/null
az acr create --resource-group "$RESOURCE_GROUP" --name "$ACR_NAME" --sku Basic --admin-enabled false --role-assignment-mode rbac >/dev/null
registry_id=$(az acr show --name "$ACR_NAME" --query id -o tsv)
az aks create --resource-group "$RESOURCE_GROUP" --name "$cluster"   --node-count 1 --node-vm-size Standard_D2s_v5 --tier free   --enable-managed-identity --attach-acr "$registry_id"   --api-server-authorized-ip-ranges "$API_ALLOWED_CIDR" --generate-ssh-keys >/dev/null
echo 'Resources created. Follow docs/AZURE.md for build, credentials and deployment.'
