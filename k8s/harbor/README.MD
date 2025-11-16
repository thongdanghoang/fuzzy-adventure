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

### 4. Configure macOS Access (OrbStack Users)

**Important:** When accessing Harbor from macOS with OrbStack, use port-forward instead of direct domain access.

#### Setup Port-Forward
```bash
# Start port-forward (keep this running in background)
kubectl port-forward -n harbor deployment/harbor-core 9090:8080 &
```

#### Configure Docker Insecure Registry
```bash
# Add localhost:9090 to insecure registries
cat > ~/.orbstack/config/docker.json << 'EOF'
{
	"insecure-registries": ["harbor.local", "localhost:9090"]
}
EOF

# Restart Docker
orb restart docker
```

#### Docker Login
```bash
echo "Harbor12345" | docker login localhost:9090 -u admin --password-stdin
```

### 5. Test Push/Pull (macOS with OrbStack)
```bash
# Tag and push an image
docker pull busybox:latest
docker tag busybox:latest localhost:9090/library/busybox:test
docker push localhost:9090/library/busybox:test

# Pull the image
docker pull localhost:9090/library/busybox:test
```

### 6. Access from Within Kubernetes Cluster

For pods running inside the cluster, use the service DNS name:
```bash
# Docker login from within cluster
docker login harbor-core.harbor.svc.cluster.local -u admin -p Harbor12345

# Or use the ingress domain (if DNS is configured)
docker login harbor.local -u admin -p Harbor12345
```

## Access Harbor UI
Open browser: https://harbor.local
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
- Default storage class is used for persistent volumes
- **macOS/OrbStack users:** Always use `kubectl port-forward` and `localhost:9090` for Docker operations
- **In-cluster access:** Use service DNS `harbor-core.harbor.svc.cluster.local` or ingress domain `harbor.local`
- Port-forward must be running during Docker push/pull operations
