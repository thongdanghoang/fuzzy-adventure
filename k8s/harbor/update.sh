curl -u "admin:Harbor12345" \
  -X PUT \
  -H "Content-Type: application/json" \
  https://harbor.local/api/v2.0/configurations \
  -d '{
        "auth_mode": "oidc_auth",
        "oidc_client_id": "harbor",
        "oidc_endpoint": "https://keycloak-thongdhse160015-dev.apps.rm3.7wse.p1.openshiftapps.com/realms/thongdhse160015",
        "oidc_client_secret": "",
        "oidc_logout": true,
        "oidc_name": "keycloak",
        "oidc_scope": "openid",
        "oidc_verify_cert": true,
        "primary_auth_mode": false,
        "oidc_groups_claim": "groups",
        "oidc_admin_groups": "/harbor-admins"
      }'
