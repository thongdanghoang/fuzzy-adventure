```bash
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update
```

```bash
helm install gitea oci://registry-1.docker.io/giteacharts/gitea
```
```bash
helm install gitea oci://docker.gitea.com/charts/gitea
```

```bash
helm install gitea gitea-charts/gitea -n gitea --create-namespace -f values.yaml
```

```bash
helm upgrade gitea gitea-charts/gitea -n gitea -f values.yaml
```

```bash
helm uninstall gitea -n gitea
kubectl delete namespace gitea
```