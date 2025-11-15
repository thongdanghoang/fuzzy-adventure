```bash
helm repo add harbor https://helm.goharbor.io
helm update
```

```bash
helm install -n harbor harbor harbor/harbor -f values.yaml -n harbor --create-namespace
```

# Update
```bash
helm upgrade -n harbor harbor harbor/harbor -f values.yaml -n harbor
```

# Ping
kubectl get pods -n harbor | grep core
```bash
kubectl exec -it harbor-core-589b95c54-4t7rz -n harbor -- sh
```

# admin
```bash
kubectl get secret -n harbor harbor-core -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 --decode
```

```bash
kubectl delete namespace harbor
```
