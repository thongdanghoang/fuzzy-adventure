# Jenkins on Kubernetes

Jenkins CI/CD server running on Kubernetes with:
- ✅ HTTP only (no TLS for local development)
- ✅ Harbor local registry for fast image pulls
- ✅ Keycloak SSO authentication
- ✅ SonarQube integration
- ✅ Gitea Git repository integration
- ✅ Pre-configured Git credentials

## Quick Start

### 1. Add Jenkins Helm repository
```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
```

### 2. Install Jenkins
```bash
helm install jenkins jenkins/jenkins -f values.yaml -n jenkins
```

### 3. Access Jenkins
- URL: http://jenkins.local
- Get admin password:
  ```bash
  kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
  ```

# Why Use Harbor Local Registry?

## Performance Benefits
Using Harbor local registry (`harbor.orb.local/library/jenkins:lts-jdk21`) instead of Docker Hub provides **significant performance improvements**:

### Speed Comparison
- **Docker Hub**: 30-60 seconds to pull image (depends on internet speed)
- **Harbor Local**: 2-5 seconds to pull image (local network speed)

### Benefits
1. **Faster Jenkins Restarts**:
   - Image already cached in local Harbor registry
   - No internet dependency
   - Consistent pull times regardless of internet connection

2. **Offline Development**:
   - Works without internet connection
   - No rate limiting from Docker Hub

3. **Image Consistency**:
   - Same image version across all environments
   - No unexpected updates from upstream

### Setup Harbor Mirror
```bash
# Pull Jenkins image from Docker Hub
docker pull jenkins/jenkins:lts-jdk21

# Tag for Harbor
docker tag jenkins/jenkins:lts-jdk21 harbor.orb.local/library/jenkins:lts-jdk21

# Push to Harbor
docker login harbor.orb.local
docker push harbor.orb.local/library/jenkins:lts-jdk21
```

### Configuration in values.yaml
```yaml
controller:
  image:
    registry: "harbor.orb.local"
    repository: "library/jenkins"
    tag: "lts-jdk21"
    pullPolicy: "IfNotPresent"
  imagePullSecrets:
    - name: harbor-registry-secret
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

## Jenkins Access
- **URL**: http://jenkins.local (HTTP only, no TLS in local environment)
- **Ingress**: Nginx (port 80)
- **Authentication**: Keycloak SSO

## Keycloak (SSO Authentication)
- **Purpose**: Single Sign-On authentication for Jenkins
- **URL**: https://keycloak.local/
- **Realm**: orbstack
- **Client**: jenkins
- **Secret**: Stored in `jenkins-keycloak-creds` Kubernetes secret
- **Credential ID**: N/A (used for authentication only)

## SonarQube (Code Quality Analysis)
- **Purpose**: Static code analysis and quality gates
- **URL**: http://sonarqube.local (HTTP only, no TLS in local environment)
- **Token**: Stored in `jenkins-sonar-creds` Kubernetes secret
- **Credential ID**: `sonar-token-id` (use this ID in Jenkins pipelines)
- **Server Name**: `SonarQube Local` (configured in JCasC)
- **Usage in Pipeline**:
  ```groovy
  withSonarQubeEnv('SonarQube Local') {
    sh 'mvn sonar:sonar'
  }
  ```

## Gitea (Git Repository)
- **Purpose**: Source code management and Git operations
- **External URL**: http://gitea.local (for browser access)
- **Internal URL**: http://gitea-http.gitea.svc.cluster.local:3000 (for Jenkins to access)
- **Token**: Stored in `jenkins-gitea-creds` Kubernetes secret
- **Credentials**:
  - **API Token**: `gitea-token-id` (for Gitea API operations)
  - **Git Credentials**: `gitea-git-credentials` (for Git clone/push operations)
    - Username: `gitea_admin`
    - Password: Gitea token (same as API token)
- **Note**:
  - Gitea không cần cấu hình server riêng như GitLab
  - Git tool configuration đã được xóa (dùng Git mặc định trong container)
  - Global git config (name/email) đã được xóa để đơn giản hóa
  - **IMPORTANT**: Jenkins phải dùng internal URL (`gitea-http.gitea.svc.cluster.local:3000`) vì `gitea.local` chỉ resolve được từ bên ngoài cluster
- **Usage in Pipeline**:
  ```groovy
  // Pipeline from SCM (recommended)
  // Configure in Jenkins UI:
  // - Pipeline from SCM → Git
  // - Repository URL: http://gitea-http.gitea.svc.cluster.local:3000/gitea_admin/your-repo.git
  // - Credentials: gitea-git-credentials
  // - Branch: */main
  // - Script Path: Jenkinsfile

  // Or use in pipeline script
  git credentialsId: 'gitea-git-credentials',
      url: 'http://gitea-http.gitea.svc.cluster.local:3000/gitea_admin/your-repo.git',
      branch: 'main'

  // Or use checkout
  checkout([
    $class: 'GitSCM',
    branches: [[name: '*/main']],
    userRemoteConfigs: [[
      url: 'http://gitea-http.gitea.svc.cluster.local:3000/gitea_admin/your-repo.git',
      credentialsId: 'gitea-git-credentials'
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

### Common Issue: Cannot connect to gitea.local
**Problem**: Jenkins cannot resolve `gitea.local` domain inside the cluster.

**Solution**: Use internal Kubernetes service URL instead:
- ❌ Wrong: `http://gitea.local/gitea_admin/repo.git`
- ✅ Correct: `http://gitea-http.gitea.svc.cluster.local:3000/gitea_admin/repo.git`

### Troubleshooting Steps

1. **Test Gitea connectivity from Jenkins pod**:
   ```bash
   # Test internal URL (should work)
   kubectl exec jenkins-0 -n jenkins -- curl -v http://gitea-http.gitea.svc.cluster.local:3000

   # Test external URL (may not work inside cluster)
   kubectl exec jenkins-0 -n jenkins -- curl -v http://gitea.local
   ```

2. **Check if Gitea token is valid**:
   ```bash
   kubectl get secret jenkins-gitea-creds -n jenkins -o jsonpath='{.data.gitea-token}' | base64 --decode
   ```

3. **Verify credentials are loaded in Jenkins**:
   - Go to Jenkins UI → Manage Jenkins → Credentials
   - Look for credentials:
     - `gitea-token-id` (API token)
     - `gitea-git-credentials` (Git username/password)

4. **Check JCasC configuration logs**:
   ```bash
   kubectl logs jenkins-0 -n jenkins | grep -i gitea
   kubectl logs jenkins-0 -n jenkins | grep -i "configuration as code"
   ```

5. **Get Gitea service details**:
   ```bash
   kubectl get svc -n gitea
   # Look for: gitea-http service on port 3000
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
