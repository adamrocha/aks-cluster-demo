#!/bin/bash
set -e

NAMESPACE="hello-world-ns"
SERVICE="hello-world-service"
# BLUE_LABEL="version=blue"
# GREEN_LABEL="version=green"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function show_status() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔵🟢 Blue/Green Deployment Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check current selector
    CURRENT_SELECTOR=$(kubectl get service "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "not-found")
    
    if [[ "$CURRENT_SELECTOR" == "blue" ]]; then
        echo -e "📡 Current Traffic Target: ${BLUE}BLUE${NC}"
    elif [[ "$CURRENT_SELECTOR" == "green" ]]; then
        echo -e "📡 Current Traffic Target: ${GREEN}GREEN${NC}"
    else
        echo "⚠️  Service not found or selector not set"
    fi
    
    echo ""
    echo "🔵 Blue Deployment:"
    kubectl get deployment hello-world-blue -n "$NAMESPACE" 2>/dev/null || echo "  ❌ Blue deployment not found"
    kubectl get pods -n "$NAMESPACE" -l version=blue 2>/dev/null | tail -n +2 || echo "  No blue pods"
    
    echo ""
    echo "🟢 Green Deployment:"
    kubectl get deployment hello-world-green -n "$NAMESPACE" 2>/dev/null || echo "  ❌ Green deployment not found"
    kubectl get pods -n "$NAMESPACE" -l version=green 2>/dev/null | tail -n +2 || echo "  No green pods"
    
    echo ""
    echo "🌐 Service Information:"
    kubectl get service "$SERVICE" -n "$NAMESPACE" 2>/dev/null || echo "  ❌ Service not found"
    
    echo ""
    EXTERNAL_IP=$(kubectl get service "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [[ -n "$EXTERNAL_IP" ]]; then
        echo "🔗 LoadBalancer IP: http://$EXTERNAL_IP"
    else
        echo "⏳ LoadBalancer IP not yet assigned"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

function switch_to_blue() {
    echo -e "${BLUE}🔵 Switching traffic to BLUE deployment...${NC}"
    kubectl patch service "$SERVICE" -n "$NAMESPACE" -p '{"spec":{"selector":{"app":"hello-world","version":"blue"}}}'
    echo "✅ Traffic switched to BLUE"
    echo ""
    show_status
}

function switch_to_green() {
    echo -e "${GREEN}🟢 Switching traffic to GREEN deployment...${NC}"
    kubectl patch service "$SERVICE" -n "$NAMESPACE" -p '{"spec":{"selector":{"app":"hello-world","version":"green"}}}'
    echo "✅ Traffic switched to GREEN"
    echo ""
    show_status
}

function rollback() {
    CURRENT=$(kubectl get service "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.spec.selector.version}' 2>/dev/null)
    
    if [[ "$CURRENT" == "blue" ]]; then
        echo "⏮️  Current version is BLUE, rolling back to GREEN..."
        switch_to_green
    elif [[ "$CURRENT" == "green" ]]; then
        echo "⏮️  Current version is GREEN, rolling back to BLUE..."
        switch_to_blue
    else
        echo "❌ Cannot determine current version"
        exit 1
    fi
}

# Main
case "${1:-status}" in
    status)
        show_status
        ;;
    blue)
        switch_to_blue
        ;;
    green)
        switch_to_green
        ;;
    rollback)
        rollback
        ;;
    *)
        echo "Usage: $0 {status|blue|green|rollback}"
        echo ""
        echo "  status   - Show current deployment status"
        echo "  blue     - Switch traffic to blue deployment"
        echo "  green    - Switch traffic to green deployment"
        echo "  rollback - Switch to the other deployment"
        exit 1
        ;;
esac
