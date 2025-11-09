```bash
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update
```
```bash
kubectl create namespace sonarqube
export MONITORING_PASSCODE="April03,2001"
helm upgrade -f values.yaml --install -n sonarqube sonarqube sonarqube/sonarqube
```

```bash
helm uninstall -n sonarqube sonarqube
kubectl delete namespace sonarqube
```

```bash
kubectl get pods --all-namespaces
```