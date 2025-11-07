```bash
helm repo add harbor https://helm.goharbor.io
helm install -n harbor harbor harbor/harbor -f values.yaml -n harbor --create-namespace
```

# admin
```bash
kubectl get secret -n harbor harbor-core -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 --decode
```

```bash
helm uninstall harbor
```