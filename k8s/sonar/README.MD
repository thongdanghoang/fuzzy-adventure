```bash
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update
```
```bash
kubectl create namespace sonarqube
```

Instead of storing the monitoring passcode directly in the values file (which is not secure), create a Kubernetes secret:
```bash
kubectl create secret generic sonarqube-monitoring-passcode --from-literal=passcode='YOUR_SECURE_PASSCODE' -n sonarqube
```

Then deploy SonarQube using the values file which references the secret:
```bash
helm upgrade -f values.yaml --install -n sonarqube sonarqube sonarqube/sonarqube
```

To uninstall:
```bash
helm uninstall -n sonarqube sonarqube
kubectl delete namespace sonarqube
```

To check the status of pods:
```bash
kubectl get pods --all-namespaces
```