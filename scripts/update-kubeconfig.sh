#!/bin/bash

# Script para atualizar kubeconfig do AKS
# Usage: ./scripts/update-kubeconfig.sh

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se Terraform está instalado
if ! command -v terraform &> /dev/null; then
    print_error "Terraform não encontrado"
    exit 1
fi

# Verificar se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl não encontrado"
    exit 1
fi

# Verificar se Azure CLI está instalado
if ! command -v az &> /dev/null; then
    print_error "Azure CLI não encontrado"
    exit 1
fi

print_message "Obtendo informações do cluster..."

RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null)
CLUSTER_NAME=$(terraform output -raw aks_cluster_name 2>/dev/null)

if [ -z "$RESOURCE_GROUP" ] || [ -z "$CLUSTER_NAME" ]; then
    print_error "Não foi possível obter informações do cluster"
    print_error "Execute 'terraform apply' primeiro"
    exit 1
fi

print_message "Resource Group: $RESOURCE_GROUP"
print_message "Cluster: $CLUSTER_NAME"

print_message "Atualizando kubeconfig..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

print_message "Verificando conexão..."
kubectl cluster-info

print_message "Kubeconfig atualizado com sucesso!"
print_message "Você pode usar kubectl para gerenciar o cluster"
