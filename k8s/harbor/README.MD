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

### 4. Configure for OrbStack (Mac)

#### a. Add to /etc/hosts
```bash
sudo sh -c 'echo "192.168.139.2 harbor.orb.local" >> /etc/hosts'
```

#### b. Configure Docker for Insecure Registry
Edit `~/.orbstack/config/docker.json`:
```json
{
  "insecure-registries": ["harbor.orb.local"]
}
```

#### c. Configure OrbStack DNS (Optional)
Create `~/.orbstack/config/domains.txt`:
```
harbor.orb.local 192.168.139.2
```

#### d. Restart Docker
```bash
orb restart docker
```

### 5. Test Docker Login
```bash
echo "Harbor12345" | docker login harbor.orb.local -u admin --password-stdin
```

### 6. Test Push/Pull
```bash
# Tag and push an image
docker pull busybox:latest
docker tag busybox:latest harbor.orb.local/library/busybox:test
docker push harbor.orb.local/library/busybox:test

# Pull the image
docker pull harbor.orb.local/library/busybox:test
```

## Access Harbor UI
Open browser: http://harbor.orb.local
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
- The registry uses `harbor.orb.local` domain which works reliably with OrbStack
- Domain `.local` may have conflicts with mDNS/Bonjour on macOS, so `.orb.local` is preferred
- Make sure to add the domain to Docker's insecure registries list
- Default storage class is used for persistent volumes

## Why `harbor.orb.local` instead of `harbor.local`?
On OrbStack (Mac), the `.local` TLD can conflict with mDNS/Bonjour services. While DNS resolution works for both domains via the `domains.txt` file, Docker daemon has more reliable connectivity with `.orb.local` domains. This is a known limitation of OrbStack's network architecture where the Docker daemon runs in a separate VM.
