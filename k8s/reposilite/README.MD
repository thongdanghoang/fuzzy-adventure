```bash
helm repo add reposilite https://helm.reposilite.com/
helm repo update
helm install reposilite reposilite/reposilite -n reposilite --create-namespace -f values.yaml 
```

```bash
helm upgrade reposilite reposilite/reposilite -n reposilite --create-namespace -f values.yaml 
```