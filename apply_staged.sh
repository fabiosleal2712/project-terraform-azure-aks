#!/bin/bash

# Script para aplicar a infraestrutura em etapas
# Primeiro cria as roles IAM, depois o resto da infraestrutura

echo "=== Aplicando OpenTofu em duas etapas ==="
echo

# Etapa 1: Criar apenas as roles IAM
echo "Etapa 1: Criando roles IAM..."
tofu apply -target=aws_iam_role.eks_cluster_role -target=aws_iam_role.eks_node_role -target=aws_iam_role_policy_attachment.eks_cluster_policy -target=aws_iam_role_policy_attachment.eks_worker_node_policy -target=aws_iam_role_policy_attachment.eks_cni_policy -target=aws_iam_role_policy_attachment.eks_registry_policy -auto-approve

if [ $? -eq 0 ]; then
    echo "✅ Roles IAM criadas com sucesso!"
    echo
    
    # Etapa 2: Criar o resto da infraestrutura
    echo "Etapa 2: Criando o resto da infraestrutura..."
    tofu apply -auto-approve
    
    if [ $? -eq 0 ]; then
        echo "✅ Infraestrutura completa criada com sucesso!"
    else
        echo "❌ Erro ao criar a infraestrutura completa"
        exit 1
    fi
else
    echo "❌ Erro ao criar as roles IAM"
    exit 1
fi