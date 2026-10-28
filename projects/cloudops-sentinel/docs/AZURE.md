# Optional Azure lab: ACR + AKS

**Status: source prepared; not deployed or verified against an Azure subscription by this build.** Local testing and kind CI do not prove Azure permissions, quotas, networking or billing.

## Before provisioning

You need an Azure subscription you control, current Azure CLI, kubectl, Bash, Python and enough regional VM quota. The operator must be able to create resource groups, ACR, AKS and Azure role assignments; Contributor alone does not generally grant role-assignment creation. Ask your subscription administrator for the narrowly scoped permissions required. Do not paste credentials into source or chat.

Review the [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) for your region/subscription before running. Free AKS control-plane tier does not make nodes, disks, ACR storage/build tasks or network traffic free. This project makes no fixed INR cost promise. A budget alert helps visibility; it is not a hard spending cap. Delete the lab after the session and check Cost Management later for delayed charges.

## Create a dedicated lab

Commands below contain values you must supply. No Azure credentials are included in this project.

```bash
az login
az account list --output table
export AZURE_SUBSCRIPTION_ID='YOUR-SUBSCRIPTION-ID'
az account set --subscription "$AZURE_SUBSCRIPTION_ID"
export RESOURCE_GROUP='rg-cloudops-sentinel-lab'
export ACR_NAME='YOURGLOBALLYUNIQUENAME'
export LOCATION='centralindia'
export AKS_NAME='sentinel-aks'
export API_ALLOWED_CIDR='YOUR-PUBLIC-IP/32'
bash azure/provision.sh --create-billable-resources
```

Use lowercase letters/digits for ACR_NAME (5–50 characters). Supply your real current public IPv4, not a private WSL address. The script validates a single public /32. Mobile/hotspot public IPs may change; update the authorized range deliberately if that happens.

The script checks your current subscription, refuses an existing resource group, creates a tagged dedicated group, creates Basic ACR with admin disabled and RBAC registry permissions, and creates a one-node AKS Free-tier cluster using `Standard_D2s_v5`, managed identity, ACR attachment and API source restrictions. VM size/region availability and quotas can fail. This is a beginner lab with one node, not HA or a production cluster.

The create script deliberately refuses to resume against an existing group. If a step partially fails, inspect `az resource list -g "$RESOURCE_GROUP" -o table`, decide whether to repair it manually, or run the guarded cleanup and recreate. Do not blindly loop provisioning.

## Build and deploy the actual image

From the project directory inside a clone of this repository:

```bash
TAG=$(git rev-parse --short=12 HEAD)
az acr build --registry "$ACR_NAME" --image "sentinel:$TAG" .
LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
DIGEST=$(az acr repository show --name "$ACR_NAME" --image "sentinel:$TAG" --query digest -o tsv)
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --context sentinel-aks-lab
kubectl config current-context
# Confirm that the displayed context really belongs to your new lab.
export EXPECTED_CONTEXT='sentinel-aks-lab'
export IMAGE="$LOGIN_SERVER/sentinel@$DIGEST"
bash scripts/deploy.sh
kubectl -n sentinel get pods -o wide
kubectl -n sentinel port-forward svc/sentinel 8080:80
```

Run `curl -fsS http://127.0.0.1:8080/readyz` and `/api/status` in another terminal. `az acr build` performs a remote build; your laptop need not run Docker for this path, though it still needs CLI tools. Registry queries/builds require operator ACR permissions. Managed identity handles image pulls; role-assignment propagation may delay the first pull.

A successful port-forward verifies operator-to-pod access through the API. It does not prove Service load balancing, availability under load, Azure Monitor integration or private networking.

## Investigate and save evidence

```bash
bash scripts/diagnose.sh sentinel
kubectl -n sentinel rollout history deployment/sentinel
kubectl -n sentinel get endpointslices
```

Save sanitized outputs, image digest, deployment date, actual configuration, what failed and how you recovered. Do not publish credentials or full kubeconfig. The disruptive drill script refuses Azure contexts; use the local lab to learn the fault scenarios first.

## Cleanup

Before deletion, list everything in the dedicated group. Copy the node resource group name while the cluster still exists:

```bash
az resource list --resource-group "$RESOURCE_GROUP" --output table
NODE_RESOURCE_GROUP=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --query nodeResourceGroup -o tsv)
bash azure/cleanup.sh "--delete-$RESOURCE_GROUP"
az group exists --name "$RESOURCE_GROUP"
az group exists --name "$NODE_RESOURCE_GROUP"
```

Both should eventually return false. If the managed node group remains, inspect why; do not blindly delete unrelated groups. Also check for separately retained disks, public IPs or resources outside these groups. Remove the local kubeconfig context if you no longer need it (`kubectl config delete-context sentinel-aks-lab`); this only removes local configuration, not cloud resources.

## Official references checked 28 October 2026

- [AKS and ACR integration](https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration): kubelet managed identity and the ABAC distinction.
- [Azure CLI ACR commands](https://learn.microsoft.com/en-us/cli/azure/acr?view=azure-cli-latest): role-assignment-mode and registry operations.
- [Kubernetes probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/): startup/readiness/liveness semantics.
- [Kubernetes security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/): non-root and filesystem controls.
- [kind quick start](https://kind.sigs.k8s.io/docs/user/quick-start/): local cluster and image loading.


## Alternative Linux VM deployment path

The [Linux VM lab](LINUX_VM_LAB.md) uses `azure/linux-vm/main.bicep` and a guarded helper instead of AKS. The app stays on loopback behind an SSH tunnel. Review what-if, source-IP restriction, public-key authentication, VM/public-IP/disk costs and dedicated-group cleanup. This is a separate optional resource group, not a migration of the AKS lab.
