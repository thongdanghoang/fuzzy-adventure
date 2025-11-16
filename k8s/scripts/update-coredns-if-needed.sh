#!/bin/bash
set -e

echo "=== CoreDNS IP Update Script ==="

# Get current Nginx Ingress IP (this is the authoritative IP)
CURRENT_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$CURRENT_IP" ]; then
    echo "❌ Failed to get Nginx Ingress IP. Is ingress-nginx installed?"
    exit 1
fi

echo "Current Nginx Ingress IP: $CURRENT_IP"

# Get configured IP from CoreDNS NodeHosts
CONFIGURED_IP=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.NodeHosts}' | awk '{print $1; exit}')

echo "Configured CoreDNS IP: $CONFIGURED_IP"

# Compare IPs
if [ "$CURRENT_IP" = "$CONFIGURED_IP" ]; then
    echo "✅ IPs match. No update needed."
    exit 0
fi

echo "⚠️  IP mismatch detected!"
echo "   Old IP: $CONFIGURED_IP"
echo "   New IP: $CURRENT_IP"
echo ""
echo "Updating CoreDNS configuration..."

# Update CoreDNS NodeHosts using kubectl edit approach
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  NodeHosts: |
    ${CURRENT_IP} orbstack
    ${CURRENT_IP} jenkins.local
    ${CURRENT_IP} harbor.local
    ${CURRENT_IP} gitea.local
    ${CURRENT_IP} sonarqube.local
EOF

echo "✅ CoreDNS ConfigMap updated"

# Restart CoreDNS to apply changes
echo "Restarting CoreDNS deployment..."
kubectl rollout restart deployment coredns -n kube-system

# Wait for CoreDNS to be ready
echo "Waiting for CoreDNS to be ready..."
kubectl rollout status deployment coredns -n kube-system --timeout=60s

echo ""
echo "✅ CoreDNS update complete!"
echo ""
echo "Updated DNS entries:"
kubectl get configmap coredns -n kube-system -o jsonpath='{.data.NodeHosts}'
echo ""
