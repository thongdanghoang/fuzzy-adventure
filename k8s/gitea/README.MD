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
  --namespace=gitea
```

#### OAuth Client Secret (Keycloak)
```bash
kubectl create secret generic gitea-oauth-secret \
  --from-literal=key='gitea' \
  --from-literal=secret='YOUR_KEYCLOAK_CLIENT_SECRET' \
  --namespace=gitea
```

**Note**: Replace `YOUR_ADMIN_PASSWORD` and `YOUR_KEYCLOAK_CLIENT_SECRET` with actual values.

### 2. Verify Secrets
```bash
kubectl get secrets -n gitea | grep gitea
```

Expected output:
```
gitea-admin-secret           Opaque               3      10s
gitea-oauth-secret           Opaque               2      8s
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
kubectl delete secret gitea-admin-secret -n gitea
kubectl delete secret gitea-oauth-secret -n gitea
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

## Access Information
- Gitea is accessible via HTTP at: http://gitea.local
- Ingress is enabled with nginx controller

## Troubleshooting

### Check if secrets exist
```bash
kubectl describe secret gitea-admin-secret -n gitea
kubectl describe secret gitea-oauth-secret -n gitea
```

### View secret values (base64 encoded)
```bash
kubectl get secret gitea-admin-secret -n gitea -o yaml
```

### Decode secret values
```bash
kubectl get secret gitea-admin-secret -n gitea -o jsonpath='{.data.password}' | base64 -d
```
