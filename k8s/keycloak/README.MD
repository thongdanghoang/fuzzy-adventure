# Keycloak Deployment on OKD

Keycloak Identity and Access Management system deployed on OpenShift (OKD) cluster.

## Deployment Information

- **Chart**: `oci://registry-1.docker.io/bitnamicharts/keycloak`
- **Version**: 25.2.0 (Keycloak 26.3.3)
- **Namespace**: `thongdhse160015-dev`
- **Database**: External PostgreSQL (standalone deployment)
- **Access URL**: https://keycloak-thongdhse160015-dev.apps.rm3.7wse.p1.openshiftapps.com

## Installation

### Deploy Keycloak
```bash
helm install keycloak oci://registry-1.docker.io/bitnamicharts/keycloak \
  -f values.okd.yaml \
  -n thongdhse160015-dev
```

### Create OpenShift Route (HTTPS)
```bash
oc create route edge keycloak \
  --service=keycloak \
  --port=http \
  --insecure-policy=Redirect \
  -n thongdhse160015-dev
```

## Upgrade

```bash
helm upgrade keycloak oci://registry-1.docker.io/bitnamicharts/keycloak \
  -f values.okd.yaml \
  -n thongdhse160015-dev
```

## Configuration

### External Database
Keycloak uses an external PostgreSQL database:
- **Host**: `postgresql.thongdhse160015-dev.svc.cluster.local`
- **Port**: `5432`
- **Database**: `bitnami_keycloak`
- **User**: `bn_keycloak`
- **Password**: Configured in `values.okd.yaml`

See `../postgresql/README.MD` for database management.

### Proxy Configuration
- **Proxy Mode**: `edge` (TLS termination at OpenShift Router)
- **Proxy Headers**: `xforwarded`
- **Hostname**: `keycloak-thongdhse160015-dev.apps.rm3.7wse.p1.openshiftapps.com`

## Common Operations

### View Chart Values
```bash
helm show values oci://registry-1.docker.io/bitnamicharts/keycloak
```

### Check Pod Status
```bash
kubectl get pods -l app.kubernetes.io/name=keycloak -n thongdhse160015-dev
```

### View Logs
```bash
kubectl logs -f keycloak-0 -n thongdhse160015-dev
```

### Access Admin Console
1. Get admin password:
   ```bash
   kubectl get secret keycloak -n thongdhse160015-dev -o jsonpath="{.data.admin-password}" | base64 -d
   ```

2. Open browser: https://keycloak-thongdhse160015-dev.apps.rm3.7wse.p1.openshiftapps.com

3. Login with username `user` and the password from step 1

## Troubleshooting

### Check Database Connection
```bash
kubectl logs keycloak-0 -n thongdhse160015-dev | grep -i "database\|postgres\|connection"
```

### Verify Realm Access
```bash
kubectl exec -it keycloak-0 -- curl -s http://localhost:8080/realms/master
```

### Restart Keycloak
```bash
kubectl delete pod keycloak-0 -n thongdhse160015-dev
# StatefulSet will automatically recreate it
```

## Migration Notes

**Previous Setup**: Keycloak with bundled PostgreSQL
**Current Setup**: Keycloak with external PostgreSQL

**Migration Date**: 2025-11-16
**Migration Steps**:
1. Deployed standalone PostgreSQL
2. Dumped data from bundled database
3. Restored to standalone PostgreSQL
4. Updated Keycloak to use external database
5. Old PVC `data-keycloak-postgresql-0` retained as backup

## Cleanup

### Remove Keycloak (keeps database)
```bash
helm uninstall keycloak -n thongdhse160015-dev
oc delete route keycloak -n thongdhse160015-dev
```

⚠️ **Note**: This does NOT delete the PostgreSQL database. Data is preserved.
