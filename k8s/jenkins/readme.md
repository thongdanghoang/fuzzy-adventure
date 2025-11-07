```bash
helm install my-jenkins jenkins/jenkins
helm repo update
helm install my-jenkins jenkins/jenkins
```
```bash
kubectl --namespace jenkins get secret my-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
```