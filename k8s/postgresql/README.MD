# PostgreSQL Standalone Deployment

Standalone PostgreSQL deployment for Keycloak and other services in OKD cluster.

## Deployment Information

- **Chart**: `oci://registry-1.docker.io/bitnamicharts/postgresql`
- **Version**: 18.1.9 (PostgreSQL 18.1.0)
- **Namespace**: `thongdhse160015-dev`
- **Image**: `docker.io/bitnamilegacy/postgresql:17.6.0-debian-12-r0`

## Installation

```bash
helm install postgresql oci://registry-1.docker.io/bitnamicharts/postgresql \
  -f values.okd.yaml \
  -n thongdhse160015-dev
```

## Configuration

### Database Credentials
- **Database**: `bitnami_keycloak`
- **User**: `bn_keycloak`
- **Password**: Defined in `values.okd.yaml` (default: `keycloak123`)
- **Postgres Admin Password**: Defined in `values.okd.yaml` (default: `postgres123`)

⚠️ **Security Note**: Change default passwords in production!

### Service Connection
- **Internal DNS**: `postgresql.thongdhse160015-dev.svc.cluster.local`
- **Port**: `5432`

## Resource Allocation

- **CPU Requests**: 250m
- **CPU Limits**: 500m
- **Memory Requests**: 256Mi
- **Memory Limits**: 512Mi
- **Storage**: 8Gi (default storage class)

## Common Operations

### Connect to PostgreSQL

```bash
# Get password
export POSTGRES_PASSWORD=$(kubectl get secret --namespace thongdhse160015-dev postgresql -o jsonpath="{.data.password}" | base64 -d)

# Connect via kubectl
kubectl run postgresql-client --rm --tty -i --restart='Never' \
  --namespace thongdhse160015-dev \
  --image docker.io/bitnamilegacy/postgresql:17.6.0-debian-12-r0 \
  --env="PGPASSWORD=$POSTGRES_PASSWORD" \
  --command -- psql --host postgresql -U bn_keycloak -d bitnami_keycloak -p 5432
```

### Backup Database

```bash
kubectl exec -it postgresql-0 -n thongdhse160015-dev -- \
  bash -c "PGPASSWORD='keycloak123' pg_dump -U bn_keycloak -d bitnami_keycloak" > backup.sql
```

### Restore Database

```bash
kubectl exec -i postgresql-0 -n thongdhse160015-dev -- \
  bash -c "PGPASSWORD='keycloak123' psql -U bn_keycloak -d bitnami_keycloak" < backup.sql
```

## Migration from Keycloak Bundled PostgreSQL

Data was migrated from the bundled `keycloak-postgresql` to this standalone instance:

1. Dumped data from `keycloak-postgresql-0`
2. Deployed standalone PostgreSQL
3. Restored data to new instance
4. Updated Keycloak configuration to use external database

The old PVC `data-keycloak-postgresql-0` is retained as backup.

## Monitoring

Check pod status:
```bash
kubectl get pods -l app.kubernetes.io/name=postgresql -n thongdhse160015-dev
```

View logs:
```bash
kubectl logs postgresql-0 -n thongdhse160015-dev
```

## Troubleshooting

### Check PostgreSQL is Ready
```bash
kubectl exec -it postgresql-0 -- pg_isready -U bn_keycloak -d bitnami_keycloak
```

### Verify Tables
```bash
kubectl exec -it postgresql-0 -- bash -c "PGPASSWORD='keycloak123' psql -U bn_keycloak -d bitnami_keycloak -c '\dt'"
```

### Check Connections
```bash
kubectl exec -it postgresql-0 -- bash -c "PGPASSWORD='keycloak123' psql -U bn_keycloak -d bitnami_keycloak -c 'SELECT * FROM pg_stat_activity;'"
```

## Cleanup

To remove the old keycloak-postgresql PVC (after verifying everything works):

```bash
kubectl delete pvc data-keycloak-postgresql-0 -n thongdhse160015-dev
```

⚠️ **Warning**: This will permanently delete the old data. Ensure you have backups!
