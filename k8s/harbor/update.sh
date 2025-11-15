curl -u "admin:Harbor12345" \
  -X PUT \
  -H "Content-Type: application/json" \
  https://harbor.local/api/v2.0/configurations \
  -d '{
        "auth_mode": "oidc_auth",
        "oidc_client_id": "harbor",
        "oidc_endpoint": "https://keycloak.local/realms/orbstack",
        "oidc_client_secret": "6XIETELLe6BI9DzLi4rmmpFrV6KAkRSV",
        "oidc_logout": true,
        "oidc_name": "keycloak",
        "oidc_scope": "openid",
        "oidc_verify_cert": false,
        "primary_auth_mode": false,
        "oidc_groups_claim": "groups",
        "oidc_admin_groups": "/harbor-admins"
      }'
