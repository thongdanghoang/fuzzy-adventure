# Add Jenkins Helm repository
```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
```

# Install Jenkins
```bash
helm install jenkins jenkins/jenkins -f values.yaml -n jenkins
```

# Get password
```bash
kubectl --namespace jenkins get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
```

# Uninstall
```bash
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
kubectl get all,pvc,secret -n jenkins
```

# Integration
## Create KeyCloak credentials secret
```bash
kubectl delete secret jenkins-keycloak-creds -n jenkins
kubectl create secret generic jenkins-keycloak-creds \
  --from-literal=client-secret='CHANGEME' \
  --namespace jenkins
kubectl get secret -n jenkins jenkins-keycloak-creds -o yaml
```

## Create Sonar credentials secret
```bash
kubectl delete secret jenkins-sonar-creds -n jenkins
kubectl create secret generic jenkins-sonar-creds \
  --from-literal=sonar-token='CHANGEME' \
  --namespace jenkins
kubectl get secret -n jenkins jenkins-sonar-creds -o yaml
```

## Create Docker registry credentials secret for Harbor
```bash
kubectl create secret docker-registry jenkins-harbor-secret \
  --docker-server=harbor-core.harbor.svc.cluster.local:80 \
  --docker-username=admin \
  --docker-password=Harbor12345 \
  --docker-email=admin@harbor.local \
  --namespace jenkins
kubectl get secret -n jenkins jenkins-harbor-secret -o yaml
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
    - name: SONAR_SERVER_URL
      value: "http://sonarqube.local"
    - name: SONAR_AUTH_TOKEN
      valueFrom:
        secretKeyRef:
          name: jenkins-sonar-creds
          key: sonar-token
    - name: SONAR_TOKEN_ID
      value: "sonar-token-id"
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
      credentials: |
        credentials:
          system:
            domainCredentials:
              - credentials:
                  - string:
                      scope: GLOBAL
                      id: "${SONAR_TOKEN_ID}"  
                      secret: "${SONAR_AUTH_TOKEN}"
                      description: "SonarQube Server Authentication Token"
      sonar-config: |
        unclassified:
          sonarGlobalConfiguration:
            buildWrapperEnabled: true
            installations:
              - name: "SonarQube"
                serverUrl: "${SONAR_SERVER_URL}"
                serverToken: "${SONAR_TOKEN_ID}"
                triggers:
                  skipScmCause: false
                  skipUpstreamCause: false
```

# Check log with correlation ID
```bash
kubectl logs jenkins-0 -n jenkins | grep -B 5 -A 30 "248242bb-6a1a-42ba-8f6d-1a0978cdc2ca"
kubectl exec jenkins-0 -n jenkins -- curl -v https://keycloak.local
kubectl get configmap coredns -n kube-system -o yaml
kubectl edit configmap coredns -n kube-system
```

# Debug
```bash
kubectl describe pod jenkins-0 -n jenkins
kubectl logs jenkins-0 -n jenkins -c init
kubectl get ingress --all-namespaces
```

# Upgrade
```bash
helm upgrade jenkins jenkins/jenkins -f values.yaml -n jenkins
```
