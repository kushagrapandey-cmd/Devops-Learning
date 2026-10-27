#!/usr/bin/env bash
set -euo pipefail
: "${AZURE_SUBSCRIPTION_ID:?Set subscription ID}"
: "${RESOURCE_GROUP:?Set the dedicated lab resource group}"
[[ "${1:-}" == "--delete-$RESOURCE_GROUP" ]] || { echo "Required flag: --delete-$RESOURCE_GROUP" >&2; exit 2; }
[[ "$(az account show --query id -o tsv)" == "$AZURE_SUBSCRIPTION_ID" ]] || { echo 'Subscription mismatch' >&2; exit 2; }
[[ "$(az group show --name "$RESOURCE_GROUP" --query tags.project -o tsv)" == cloudops-sentinel ]] || { echo 'Project tag mismatch' >&2; exit 2; }
az group delete --name "$RESOURCE_GROUP" --yes
# AKS normally removes its managed node resource group; verify separately.
az group exists --name "$RESOURCE_GROUP"
