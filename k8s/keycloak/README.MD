```bash
helm install keycloak oci://registry-1.docker.io/bitnamicharts/keycloak -f values.yaml -n keycloak --create-namespace
```

```bash
helm upgrade keycloak oci://registry-1.docker.io/bitnamicharts/keycloak -f values.yaml -n keycloak
kubectl -n keycloak get secret keycloak.local-tls -o jsonpath='{.data.tls\.crt}' | base64 --decode > keycloak-ca.crt
```

```bash
helm install my-release oci://registry-1.docker.io/bitnamicharts/keycloak
helm show values oci://registry-1.docker.io/bitnamicharts/keycloak
```

```bash
kubectl delete namespace keycloak
```
