```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
```
```bash
helm install jenkins jenkins/jenkins -f values.yaml -n jenkins --create-namespace
```
```bash
helm upgrade jenkins jenkins/jenkins -f values.yaml -n jenkins
```
```bash
kubectl --namespace jenkins get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
```
```bash
helm uninstall jenkins jenkins/jenkins
kubectl delete namespace jenkins
```

```bash
kubectl create secret docker-registry harbor-credentials \
    --namespace=jenkins \
    --docker-server=harbor-core.harbor.svc.cluster.local:80 \
    --docker-username=admin \
    --docker-password=April03,2001 \
    --docker-email=email@example.com
```