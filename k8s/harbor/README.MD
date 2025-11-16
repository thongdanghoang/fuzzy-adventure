# Harbor Registry Setup

## Prerequisites
- Kubernetes cluster (OrbStack/K3s/etc.)
- Helm 3
- Nginx Ingress Controller

## Installation

### 1. Add Harbor Helm Repository
```bash
helm repo add harbor https://helm.goharbor.io
helm repo update
```

### 2. Deploy Harbor
```bash
helm install harbor harbor/harbor -f values.yaml -n harbor --create-namespace
```

### 3. Get Admin Password
```bash
kubectl get secret -n harbor harbor-core -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 --decode
```
Default password: `Harbor12345`

### 4. Test Docker Login
```bash
echo "Harbor12345" | docker login harbor.local -u admin --password-stdin
```

### 5. Test Push/Pull
```bash
# Tag and push an image
docker pull busybox:latest
docker tag busybox:latest harbor.local/library/busybox:test
docker push harbor.local/library/busybox:test

# Pull the image
docker pull harbor.local/library/busybox:test
```

## Access Harbor UI
Open browser: http://harbor.local
- Username: `admin`
- Password: `Harbor12345` (or get from secret)

## Update Harbor
```bash
helm upgrade harbor harbor/harbor -f values.yaml -n harbor
```

## Debug

### Check Pods Status
```bash
kubectl get pods -n harbor
```

### Check Ingress
```bash
kubectl get ingress -n harbor
```

### Access Harbor Core Pod
```bash
kubectl exec -it $(kubectl get pods -n harbor | grep core | awk '{print $1}') -n harbor -- sh
```

### Check Logs
```bash
kubectl logs -n harbor $(kubectl get pods -n harbor | grep core | awk '{print $1}')
```

## Uninstall
```bash
helm uninstall harbor -n harbor
kubectl delete namespace harbor
```

## Notes
- Harbor is configured for HTTP (no TLS) for local development
- The registry uses `harbor.local` domain which works reliably with OrbStack
- Domain `.local` may have conflicts with mDNS/Bonjour on macOS, so `.orb.local` is preferred
- Make sure to add the domain to Docker's insecure registries list
- Default storage class is used for persistent volumes
