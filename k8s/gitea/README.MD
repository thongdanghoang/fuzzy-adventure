# Gitea Helm Chart Setup

## Prerequisites

### 1. Add Helm Repository
```bash
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update
```

## Installation

### 1. Create Kubernetes Secrets

**IMPORTANT**: Secrets are NOT stored in Git for security reasons. Create them manually in your cluster:

#### Admin Credentials Secret
```bash
kubectl create secret generic gitea-admin-secret \
  --from-literal=username=gitea_admin \
  --from-literal=password='YOUR_ADMIN_PASSWORD' \
  --from-literal=email='gitea@local.domain' \
  --namespace=default
```

#### OAuth Client Secret (Keycloak)
```bash
kubectl create secret generic gitea-oauth-secret \
  --from-literal=keycloak-client-secret='YOUR_KEYCLOAK_CLIENT_SECRET' \
  --namespace=default
```

**Note**: Replace `YOUR_ADMIN_PASSWORD` and `YOUR_KEYCLOAK_CLIENT_SECRET` with actual values.

### 2. Verify Secrets
```bash
kubectl get secrets -n default | grep gitea
```

Expected output:
```
gitea-admin-secret           Opaque               3      10s
gitea-oauth-secret           Opaque               1      8s
```

### 3. Install Gitea
```bash
helm install gitea gitea-charts/gitea -n gitea --create-namespace -f values.yaml
```

## Management

### Upgrade Gitea
```bash
helm upgrade gitea gitea-charts/gitea -n gitea -f values.yaml
```

### Uninstall Gitea
```bash
helm uninstall gitea -n gitea
kubectl delete namespace gitea
```

### Delete Secrets (if needed)
```bash
kubectl delete secret gitea-admin-secret -n default
kubectl delete secret gitea-oauth-secret -n default
```

## Configuration

The `values.yaml` file uses `existingSecret` references instead of hardcoded passwords:

```yaml
gitea:
  admin:
    existingSecret: gitea-admin-secret  # References the Kubernetes secret
  oauth:
    - name: 'Keycloak'
      existingSecret: gitea-oauth-secret  # References the Kubernetes secret
```

This approach ensures:
- ✅ Secrets are NOT committed to Git
- ✅ Secrets are managed directly in Kubernetes
- ✅ Same pattern as other services (e.g., Jenkins Harbor secret)

## Troubleshooting

### Check if secrets exist
```bash
kubectl describe secret gitea-admin-secret -n default
kubectl describe secret gitea-oauth-secret -n default
```

### View secret values (base64 encoded)
```bash
kubectl get secret gitea-admin-secret -n default -o yaml
```

### Decode secret values
```bash
kubectl get secret gitea-admin-secret -n default -o jsonpath='{.data.password}' | base64 -d
```
