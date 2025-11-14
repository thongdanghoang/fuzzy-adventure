# Add the Jetstack Helm repository
```bash
helm repo add jetstack https://charts.jetstack.io --force-update
```

### Install the cert-manager helm chart
```bash
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.19.1 -f values.yaml
```

# Create the local Certificate Authority
```bash
openssl genrsa -out rootCA.key 4096
```

### Create cert from CA
```bash
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -config ca.conf
```

### Put Root CA to Kubernetes
```bash
kubectl create secret tls local-ca-secret --cert=rootCA.crt --key=rootCA.key --namespace=cert-manager
```

# ClusterIssuer
```bash
kubectl apply -f ca-cluster-issuer.yaml
kubectl get clusterissuer local-ca-issuer -o wide
```

# Clean
```bash
helm delete cert-manager --namespace cert-manager
kubectl delete crd \
  issuers.cert-manager.io \
  clusterissuers.cert-manager.io \
  certificates.cert-manager.io \
  certificaterequests.cert-manager.io \
  orders.acme.cert-manager.io \
  challenges.acme.cert-manager.io
```

```bash
kubectl delete secret tls local-ca-secret
```
