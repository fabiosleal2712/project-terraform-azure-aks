#!/bin/bash

# Script para deploy da infraestrutura AKS no Azure
# Usage: ./scripts/deploy.sh [environment]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para print colorido
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar argumentos
ENVIRONMENT=${1:-dev}

print_message "Iniciando deploy para ambiente: $ENVIRONMENT"

# Verificar se Azure CLI está instalado
if ! command -v az &> /dev/null; then
    print_error "Azure CLI não encontrado. Instale com: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Verificar se Terraform ou OpenTofu está instalado
TF_CMD=""
if command -v terraform &> /dev/null; then
    TF_CMD="terraform"
    print_message "Usando Terraform: $(terraform version | head -n1)"
elif command -v tofu &> /dev/null; then
    TF_CMD="tofu"
    print_message "Usando OpenTofu: $(tofu version | head -n1)"
else
    print_error "Terraform ou OpenTofu não encontrado. Instale um deles:"
    print_error "  Terraform: https://www.terraform.io/downloads"
    print_error "  OpenTofu: https://opentofu.org/docs/intro/install"
    exit 1
fi

# Verificar se está logado no Azure
print_message "Verificando login no Azure..."
if ! az account show &> /dev/null; then
    print_error "Não está logado no Azure. Execute: az login"
    exit 1
fi

# Mostrar subscription atual
SUBSCRIPTION=$(az account show --query name -o tsv)
print_message "Subscription atual: $SUBSCRIPTION"

read -p "Deseja continuar com esta subscription? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deploy cancelado pelo usuário"
    exit 1
fi

# Criar arquivo terraform.tfvars se não existir
if [ ! -f "terraform.tfvars" ]; then
    print_warning "Arquivo terraform.tfvars não encontrado"
    print_message "Copiando de terraform.tfvars.example..."
    cp terraform.tfvars.example terraform.tfvars
    print_warning "IMPORTANTE: Edite terraform.tfvars antes de continuar!"
    read -p "Pressione Enter após editar o arquivo..."
fi

# Terraform/OpenTofu Init
print_message "Inicializando $TF_CMD..."
$TF_CMD init

# Terraform/OpenTofu Validate
print_message "Validando configuração..."
$TF_CMD validate

# Terraform/OpenTofu Format
print_message "Formatando arquivos..."
$TF_CMD fmt -recursive

# Terraform/OpenTofu Plan
print_message "Gerando plano de execução..."
$TF_CMD plan -out=tfplan -var="environment=$ENVIRONMENT"

# Confirmar apply
print_warning "O plano acima será aplicado."
read -p "Deseja continuar com o apply? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deploy cancelado pelo usuário"
    rm -f tfplan
    exit 1
fi

# Terraform/OpenTofu Apply
print_message "Aplicando infraestrutura..."
$TF_CMD apply tfplan

# Limpar arquivo de plano
rm -f tfplan

# Obter outputs
print_message "Obtendo informações do cluster..."
RESOURCE_GROUP=$($TF_CMD output -raw resource_group_name)
CLUSTER_NAME=$($TF_CMD output -raw aks_cluster_name)
ACR_NAME=$($TF_CMD output -raw acr_name)

# Conectar ao cluster
print_message "Configurando kubectl para conectar ao cluster..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

# Verificar nodes
print_message "Verificando nodes do cluster..."
kubectl get nodes

# Verificar namespaces
print_message "Verificando namespaces..."
kubectl get namespaces

# Login no ACR
print_message "Fazendo login no Azure Container Registry..."
az acr login --name "$ACR_NAME"

# Resumo
print_message "=================================="
print_message "Deploy concluído com sucesso!"
print_message "=================================="
print_message "Resource Group: $RESOURCE_GROUP"
print_message "Cluster AKS: $CLUSTER_NAME"
print_message "Container Registry: $ACR_NAME"
print_message ""
print_message "Comandos úteis:"
print_message "  kubectl get nodes"
print_message "  kubectl get pods --all-namespaces"
print_message "  az aks browse --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME"
print_message ""
print_message "Para destruir a infraestrutura:"
print_message "  $TF_CMD destroy"
