```bash
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard -f values.yaml
```
```bash
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
kubectl create clusterrolebinding dashboard-admin-rb --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin
```
```bash
kubectl -n kubernetes-dashboard create token dashboard-admin
```

```bash
kubectl delete namespace kubernetes-dashboard
```