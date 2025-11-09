```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
```
```bash
helm install jenkins jenkins/jenkins -f values.yaml -n jenkins --create-namespace
```
```bash
kubectl --namespace jenkins get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
```
```bash
helm uninstall jenkins jenkins/jenkins
kubectl delete namespace jenkins
```