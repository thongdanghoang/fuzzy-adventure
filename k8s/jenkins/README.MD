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

## Create Gitea credentials secret
```bash
kubectl delete secret jenkins-gitea-creds -n jenkins
kubectl create secret generic jenkins-gitea-creds \
  --from-literal=gitea-token='dfedd87d92e98336bd8ca8b4174b2129e357db1f' \
  --namespace jenkins
kubectl get secret -n jenkins jenkins-gitea-creds -o yaml
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
    # Keycloak
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
    # SonarQube
    - name: SONAR_SERVER_URL
      value: "https://sonarqube.local"
    - name: SONAR_AUTH_TOKEN
      valueFrom:
        secretKeyRef:
          name: jenkins-sonar-creds
          key: sonar-token
    - name: SONAR_TOKEN_ID
      value: "sonar-token-id"
    # Gitea
    - name: GITEA_SERVER_URL
      value: "https://gitea.local"
    - name: GITEA_AUTH_TOKEN
      valueFrom:
        secretKeyRef:
          name: jenkins-gitea-creds
          key: gitea-token
    - name: GITEA_TOKEN_ID
      value: "gitea-token-id"
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
                  - string:
                      scope: GLOBAL
                      id: "${GITEA_TOKEN_ID}"
                      secret: "${GITEA_AUTH_TOKEN}"
                      description: "Gitea Server Authentication Token"
      sonar-config: |
        unclassified:
          sonarGlobalConfiguration:
            buildWrapperEnabled: true
            installations:
              - name: "SonarQube Local"
                serverUrl: "${SONAR_SERVER_URL}"
                serverAuthenticationToken: "${SONAR_TOKEN_ID}"
                triggers:
                  skipScmCause: false
                  skipUpstreamCause: false
          scmGit:
            globalConfigName: "Jenkins"
            globalConfigEmail: "jenkins@local"
            createAccountBasedOnEmail: false
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

# Integrations Summary

## Keycloak (SSO Authentication)
- **Purpose**: Single Sign-On authentication for Jenkins
- **URL**: https://keycloak.local/
- **Realm**: orbstack
- **Client**: jenkins
- **Secret**: Stored in `jenkins-keycloak-creds` Kubernetes secret
- **Credential ID**: N/A (used for authentication only)

## SonarQube (Code Quality Analysis)
- **Purpose**: Static code analysis and quality gates
- **URL**: https://sonarqube.local
- **Token**: Stored in `jenkins-sonar-creds` Kubernetes secret
- **Credential ID**: `sonar-token-id` (use this ID in Jenkins pipelines)
- **Usage in Pipeline**:
  ```groovy
  withSonarQubeEnv('SonarQube Local') {
    sh 'mvn sonar:sonar'
  }
  ```

## Gitea (Git Repository)
- **Purpose**: Source code management and Git operations
- **URL**: https://gitea.local
- **Token**: Stored in `jenkins-gitea-creds` Kubernetes secret
- **Credential ID**: `gitea-token-id` (use this ID in Jenkins pipelines)
- **Git Config**:
  - Name: Jenkins
  - Email: jenkins@local
- **Note**: Gitea không cần cấu hình server riêng như GitLab. Chỉ cần Git SCM global config và credentials là đủ để sử dụng.
- **Usage in Pipeline**:
  ```groovy
  // Sử dụng với Git plugin
  git credentialsId: 'gitea-token-id', url: 'https://gitea.local/your-org/your-repo.git'

  // Hoặc sử dụng checkout
  checkout([
    $class: 'GitSCM',
    branches: [[name: '*/main']],
    userRemoteConfigs: [[
      url: 'https://gitea.local/your-org/your-repo.git',
      credentialsId: 'gitea-token-id'
    ]]
  ])
  ```

## Harbor (Docker Registry)
- **Purpose**: Container image storage and distribution
- **URL**: harbor-core.harbor.svc.cluster.local:80
- **Username**: admin
- **Password**: Harbor12345
- **Secret**: `jenkins-harbor-secret` (Docker registry type)
- **Usage**: Automatically used by Jenkins agents for pulling/pushing images

# Troubleshooting

## Gitea Integration Issues
1. **Check if Gitea token is valid**:
   ```bash
   kubectl get secret jenkins-gitea-creds -n jenkins -o jsonpath='{.data.gitea-token}' | base64 --decode
   ```

2. **Test Gitea connectivity from Jenkins pod**:
   ```bash
   kubectl exec jenkins-0 -n jenkins -- curl -v https://gitea.local
   ```

3. **Verify credential is loaded in Jenkins**:
   - Go to Jenkins UI → Manage Jenkins → Credentials
   - Look for credential with ID `gitea-token-id`

4. **Check JCasC configuration logs**:
   ```bash
   kubectl logs jenkins-0 -n jenkins | grep -i gitea
   kubectl logs jenkins-0 -n jenkins | grep -i "configuration as code"
   ```

## SonarQube Integration Issues
1. **Verify SonarQube token**:
   ```bash
   kubectl get secret jenkins-sonar-creds -n jenkins -o jsonpath='{.data.sonar-token}' | base64 --decode
   ```

2. **Test SonarQube connectivity**:
   ```bash
   kubectl exec jenkins-0 -n jenkins -- curl -v https://sonarqube.local
   ```

## Keycloak Integration Issues
1. **Check Keycloak client secret**:
   ```bash
   kubectl get secret jenkins-keycloak-creds -n jenkins -o jsonpath='{.data.client-secret}' | base64 --decode
   ```

2. **Verify Keycloak realm and client configuration**:
   - Realm: orbstack
   - Client ID: jenkins
   - Valid Redirect URIs: https://jenkins.local/*

## General Debug Commands
```bash
# Check all secrets
kubectl get secrets -n jenkins

# Check Jenkins pod status
kubectl get pods -n jenkins

# View full Jenkins logs
kubectl logs jenkins-0 -n jenkins --tail=100

# Check environment variables
kubectl exec jenkins-0 -n jenkins -- env | grep -E 'GITEA|SONAR|KEYCLOAK'

# Restart Jenkins
kubectl rollout restart statefulset jenkins -n jenkins
```
