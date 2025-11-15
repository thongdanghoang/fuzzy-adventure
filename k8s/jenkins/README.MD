# Add Jenkins Helm repository
```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
```

# Install Jenkins
```bash
helm install jenkins jenkins/jenkins -f values.yaml -n jenkins --create-namespace
```

# Get password
```bash
kubectl --namespace jenkins get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
```

# Uninstall
```bash
helm uninstall jenkins jenkins/jenkins
kubectl delete namespace jenkins
```

# Create Docker registry credentials secret for Harbor
```bash
kubectl create secret docker-registry harbor-credentials \
    --namespace=jenkins \
    --docker-server=harbor-core.harbor.svc.cluster.local:80 \
    --docker-username=admin \
    --docker-password=April03,2001 \
    --docker-email=email@example.com
```

# Apply Maven repository PersistentVolumeClaim
```bash
kubectl apply -f maven-repo-pvc.yaml -n jenkins
```

# Create KeyCloak credentials secret
```bash
kubectl create secret generic jenkins-keycloak-creds \
  --from-literal=client-secret='CHANGE_ME' \
  --namespace jenkins
kubectl get secret -n jenkins jenkins-keycloak-creds -o yaml
```

## Update JCasC configuration
```yaml
controller:
  env:
    - name: KEYCLOAK_REALM
      value: "orbstack"
    - name: KEYCLOAK_AUTH_SERVER_URL
      value: "https://keycloak.local/"
    - name: DISABLE_TRUST_MANAGER
      value: "true"
    - name: ALLOW_ANY_HOSTNAME
      value: "true"
    - name: KEYCLOAK_CLIENT_SECRET
      valueFrom:
        secretKeyRef:
          name: jenkins-keycloak-creds
          key: client-secret
  JCasC:
    configScripts:
      security-realm: |
        jenkins:
          securityRealm:
            keycloak:
              keycloakJson: |
                {
                  "realm": "${KEYCLOAK_REALM}",
                  "auth-server-url": "${KEYCLOAK_AUTH_SERVER_URL}",
                  "ssl-required": "external",
                  "resource": "jenkins",
                  "credentials": {
                    "secret": "${KEYCLOAK_CLIENT_SECRET}" 
                  },
                  "confidential-port": 0,
                  "disable-trust-manager": "${DISABLE_TRUST_MANAGER}",
                  "allow-any-hostname": "${ALLOW_ANY_HOSTNAME}"
                }
```

# Debug
```bash
kubectl describe pod jenkins-0 -n jenkins
kubectl logs jenkins-0 -n jenkins -c init
```

# Upgrade
```bash
helm upgrade jenkins jenkins/jenkins -f values.yaml -n jenkins
```
