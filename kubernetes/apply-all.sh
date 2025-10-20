#!/bin/bash

# Script para aplicar configurações Kubernetes no AKS
# Usage: ./kubernetes/apply-all.sh [namespace]

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

NAMESPACE=${1:-nutri-veda-dev}

print_message "Aplicando configurações Kubernetes..."

# Criar namespaces
print_message "Criando namespaces..."
kubectl apply -f kubernetes/namespaces/

# Aplicar secrets (se existirem)
if [ -f "kubernetes/secrets/db-secret.yaml" ]; then
    print_message "Aplicando secrets..."
    kubectl apply -f kubernetes/secrets/
fi

# Aplicar deployments
print_message "Aplicando deployments..."
kubectl apply -f kubernetes/deployments/

# Aplicar ingress
print_message "Aplicando ingress..."
kubectl apply -f kubernetes/ingress/

print_message "Configurações aplicadas com sucesso!"
print_message "Verificando pods no namespace $NAMESPACE..."
kubectl get pods -n $NAMESPACE
