```bash
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace
```

```bash
helm upgrade -f values.yaml ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx
```

# You can watch the status by running
```bash
kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch
```
