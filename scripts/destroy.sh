#!/bin/bash

# Script para destruir a infraestrutura AKS no Azure
# Usage: ./scripts/destroy.sh

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

print_error "⚠️  ATENÇÃO: Este script irá DESTRUIR toda a infraestrutura!"
print_error "Todos os recursos criados serão REMOVIDOS."
echo ""

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

# Mostrar recursos que serão destruídos
print_message "Gerando plano de destruição..."
$TF_CMD plan -destroy

echo ""
print_warning "Os recursos listados acima serão DESTRUÍDOS!"
print_warning "Esta ação NÃO PODE SER DESFEITA!"
echo ""

# Confirmação 1
read -p "Digite 'yes' para confirmar a destruição: " -r
if [[ ! $REPLY == "yes" ]]; then
    print_message "Operação cancelada pelo usuário"
    exit 0
fi

# Confirmação 2 (extra segurança)
echo ""
print_error "ÚLTIMA CONFIRMAÇÃO!"
read -p "Tem CERTEZA ABSOLUTA? Digite 'destroy' para confirmar: " -r
if [[ ! $REPLY == "destroy" ]]; then
    print_message "Operação cancelada pelo usuário"
    exit 0
fi

# Terraform/OpenTofu Destroy
print_message "Iniciando destruição da infraestrutura..."
$TF_CMD destroy -auto-approve

# Limpar arquivos locais
print_message "Limpando arquivos locais..."
rm -f tfplan
rm -rf .terraform
rm -f .terraform.lock.hcl
rm -f terraform.tfstate.backup

print_message "=================================="
print_message "Destruição concluída com sucesso!"
print_message "=================================="
print_message "Todos os recursos foram removidos do Azure."
print_message "Arquivos de estado local foram limpos."
