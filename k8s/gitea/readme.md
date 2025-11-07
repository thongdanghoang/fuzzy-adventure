```bash
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update
helm install gitea gitea-charts/gitea -n gitea --create-namespace
```

```bash
helm install gitea oci://registry-1.docker.io/giteacharts/gitea
```

```bash
helm install gitea oci://docker.gitea.com/charts/gitea
```

```bash
helm uninstall gitea -n gitea
kubectl delete namespace gitea
```