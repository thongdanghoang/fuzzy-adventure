```bash
helm repo add jfrog https://charts.jfrog.io
helm repo update
```

```bash
helm upgrade --install artifactory-oss jfrog/artifactory-oss --namespace artifactory-oss --create-namespace -f values.yaml
```

```bash
helm upgrade artifactory-oss jfrog/artifactory-oss -n artifactory-oss -f values.yaml
```

```bash
kubectl get secret -n artifactory-oss artifactory-oss -o jsonpath="{.data.password}" | base64 -d
```

```bash
helm upgrade artifactory-oss jfrog/artifactory-oss --namespace artifactory-oss --create-namespace
```

```bash
helm delete artifactory-oss --namespace artifactory-oss   
kubectl delete namespace artifactory-oss
```