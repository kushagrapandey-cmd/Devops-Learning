#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
: "${RESOURCE_GROUP:?Use a dedicated Linux lab resource group}"
: "${AZURE_SUBSCRIPTION_ID:?Set subscription ID}"
: "${OPERATOR_CIDR:?Your public IPv4 /32}"
: "${SSH_PUBLIC_KEY_FILE:?Path to your public key, never private key}"
mode="${1:-what-if}"
[[ "$mode" == what-if || "$mode" == --create-billable-resources ]] || exit 2
python3 - "$OPERATOR_CIDR" "$SSH_PUBLIC_KEY_FILE" <<'CHECK'
import ipaddress, sys
from pathlib import Path
network=ipaddress.ip_network(sys.argv[1], strict=True)
assert network.version==4 and network.prefixlen==32 and network.network_address.is_global, 'Public IPv4 /32 required'
assert Path(sys.argv[2]).read_text().startswith(('ssh-ed25519 ', 'ssh-rsa ')), 'Public SSH key required'
CHECK
[[ "$(az account show --query id -o tsv)" == "$AZURE_SUBSCRIPTION_ID" ]] || { echo 'Subscription mismatch' >&2; exit 2; }
[[ "$(az group show -n "$RESOURCE_GROUP" --query tags.project -o tsv)" == cloudops-sentinel ]] || { echo 'Dedicated tagged group required' >&2; exit 2; }
operation=what-if
if [[ "$mode" == --create-billable-resources ]]; then operation=create; fi
az deployment group "$operation" -g "$RESOURCE_GROUP" --template-file main.bicep \
  --parameters operatorCidr="$OPERATOR_CIDR" sshPublicKey="$(cat "$SSH_PUBLIC_KEY_FILE")"
