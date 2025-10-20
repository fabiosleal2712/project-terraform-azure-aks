# Quick Start Guide

## 🚀 Deploy Rápido

### 1. Pré-requisitos

```bash
# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Instalar Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 2. Login no Azure

```bash
az login
az account list --output table
az account set --subscription "<subscription-id>"
```

### 3. Configurar Variáveis

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### 4. Deploy da Infraestrutura

```bash
# Opção 1: Usando script automatizado
./scripts/deploy.sh dev

# Opção 2: Manualmente
terraform init
terraform plan
terraform apply
```

### 5. Conectar ao Cluster

```bash
# Atualizar kubeconfig
./scripts/update-kubeconfig.sh

# Verificar nodes
kubectl get nodes
```

### 6. Deploy de Aplicações

```bash
# Aplicar configurações Kubernetes
cd kubernetes
./apply-all.sh nutri-veda-dev
```

## 📊 Monitoramento

```bash
# Ver pods
kubectl get pods -A

# Ver logs
kubectl logs -f deployment/chat-api -n nutri-veda-dev

# Dashboard
az aks browse --resource-group $(terraform output -raw resource_group_name) \
              --name $(terraform output -raw aks_cluster_name)
```

## 🧹 Limpeza

```bash
./scripts/destroy.sh
```

## 📚 Documentação Completa

- [Deploy Guide](docs/DEPLOY_GUIDE.md)
- [README](README.md)

## ⚡ Comandos Úteis

```bash
# Obter outputs do Terraform
terraform output

# Escalar aplicação
kubectl scale deployment chat-api --replicas=3 -n nutri-veda-dev

# Restart aplicação
kubectl rollout restart deployment/chat-api -n nutri-veda-dev

# Ver logs do Azure Monitor
az monitor log-analytics query \
  --workspace $(terraform output -raw log_analytics_workspace_id) \
  --analytics-query "ContainerLog | where TimeGenerated > ago(1h) | limit 100"
```
