# Guia de Deploy - Azure AKS

Este documento descreve o processo de deploy da aplicação Nutri-Veda no Azure Kubernetes Service (AKS).

## Pré-requisitos

- Azure CLI instalado e configurado
- Terraform instalado
- kubectl instalado
- Docker instalado (para build de imagens)

## Passo 1: Provisionar Infraestrutura

### 1.1 Configurar Variáveis

Edite o arquivo `terraform.tfvars`:

```hcl
project_name = "nutriveda"
environment  = "dev"
location     = "brazilsouth"
```

### 1.2 Deploy com Terraform

```bash
# Inicializar Terraform
terraform init

# Validar configuração
terraform validate

# Planejar mudanças
terraform plan

# Aplicar infraestrutura
terraform apply
```

### 1.3 Conectar ao Cluster

```bash
# Obter credenciais do cluster
az aks get-credentials --resource-group nutriveda-dev-rg --name nutriveda-dev-aks

# Verificar conexão
kubectl get nodes
```

## Passo 2: Configurar Container Registry

### 2.1 Login no ACR

```bash
# Obter nome do ACR
ACR_NAME=$(terraform output -raw acr_name)

# Fazer login
az acr login --name $ACR_NAME
```

### 2.2 Build e Push de Imagens

```bash
# Navegar para o diretório da aplicação
cd nutri-veda

# Build da imagem Docker
docker build -t $ACR_NAME.azurecr.io/chat-api:latest -f src/Chat/Chat.API/Dockerfile .

# Push para ACR
docker push $ACR_NAME.azurecr.io/chat-api:latest
```

### 2.3 Build Automático com ACR Tasks

```bash
# Build direto no ACR (recomendado)
az acr build --registry $ACR_NAME --image chat-api:latest -f src/Chat/Chat.API/Dockerfile ./nutri-veda
```

## Passo 3: Deploy no Kubernetes

### 3.1 Criar Namespaces

```bash
kubectl apply -f kubernetes/namespaces/
```

### 3.2 Configurar Secrets

Copie o exemplo e edite com suas credenciais:

```bash
cp kubernetes/secrets/db-secret.yaml.example kubernetes/secrets/db-secret.yaml
# Edite o arquivo com suas credenciais
kubectl apply -f kubernetes/secrets/
```

### 3.3 Deploy das Aplicações

```bash
# Atualizar manifests com nome do ACR
ACR_NAME=$(terraform output -raw acr_name)
sed -i "s/<ACR_NAME>/$ACR_NAME/g" kubernetes/deployments/*.yaml

# Aplicar deployments
kubectl apply -f kubernetes/deployments/

# Verificar status
kubectl get pods -n nutri-veda-dev
kubectl get services -n nutri-veda-dev
```

### 3.4 Configurar Ingress (Opcional)

```bash
# Instalar NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Aguardar o Load Balancer
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Aplicar regras de ingress
kubectl apply -f kubernetes/ingress/
```

## Passo 4: Monitoramento

### 4.1 Acessar Logs

```bash
# Logs de um pod específico
kubectl logs -f <pod-name> -n nutri-veda-dev

# Logs de todos os pods de um deployment
kubectl logs -f deployment/chat-api -n nutri-veda-dev
```

### 4.2 Azure Monitor

```bash
# Obter Workspace ID
terraform output log_analytics_workspace_id

# Acessar via Portal Azure
echo "https://portal.azure.com/#blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/overview"
```

### 4.3 Application Insights

```bash
# Obter Connection String
terraform output application_insights_connection_string

# Adicionar ao deployment como variável de ambiente
```

## Passo 5: CI/CD com GitHub Actions

### 5.1 Configurar Secrets no GitHub

No GitHub repository, adicione os seguintes secrets:

- `AZURE_CREDENTIALS`: Credenciais do Service Principal
- `ACR_NAME`: Nome do Container Registry
- `AKS_CLUSTER_NAME`: Nome do cluster AKS
- `AKS_RESOURCE_GROUP`: Nome do Resource Group

### 5.2 Criar Workflow

Crie `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy to AKS

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build and Push to ACR
        run: |
          az acr build --registry ${{ secrets.ACR_NAME }} \
            --image chat-api:${{ github.sha }} \
            -f src/Chat/Chat.API/Dockerfile \
            ./nutri-veda
      
      - name: Get AKS credentials
        run: |
          az aks get-credentials \
            --resource-group ${{ secrets.AKS_RESOURCE_GROUP }} \
            --name ${{ secrets.AKS_CLUSTER_NAME }}
      
      - name: Deploy to AKS
        run: |
          kubectl set image deployment/chat-api \
            chat-api=${{ secrets.ACR_NAME }}.azurecr.io/chat-api:${{ github.sha }} \
            -n nutri-veda-dev
```

## Passo 6: Troubleshooting

### Problemas Comuns

#### Pod não inicia

```bash
# Descrever o pod para ver eventos
kubectl describe pod <pod-name> -n nutri-veda-dev

# Verificar logs
kubectl logs <pod-name> -n nutri-veda-dev
```

#### Problemas de rede

```bash
# Verificar services
kubectl get svc -n nutri-veda-dev

# Testar conectividade
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Dentro do pod:
wget -O- http://chat-api-service
```

#### Problemas com ACR

```bash
# Verificar permissões
az role assignment list --scope /subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.ContainerRegistry/registries/<acr-name>

# Re-criar role assignment
terraform taint azurerm_role_assignment.aks_acr
terraform apply
```

## Comandos Úteis

```bash
# Ver todos os recursos
kubectl get all -n nutri-veda-dev

# Escalar deployment
kubectl scale deployment chat-api --replicas=3 -n nutri-veda-dev

# Restart deployment
kubectl rollout restart deployment/chat-api -n nutri-veda-dev

# Ver histórico de rollouts
kubectl rollout history deployment/chat-api -n nutri-veda-dev

# Rollback
kubectl rollout undo deployment/chat-api -n nutri-veda-dev

# Port-forward para teste local
kubectl port-forward svc/chat-api-service 8080:80 -n nutri-veda-dev

# Executar comando em um pod
kubectl exec -it <pod-name> -n nutri-veda-dev -- /bin/bash

# Ver uso de recursos
kubectl top nodes
kubectl top pods -n nutri-veda-dev
```

## Limpeza

Para remover toda a infraestrutura:

```bash
# Deletar recursos Kubernetes
kubectl delete namespace nutri-veda-dev

# Destruir infraestrutura Terraform
terraform destroy
```

## Próximos Passos

1. **Configurar Auto Scaling**: Implementar HPA (Horizontal Pod Autoscaler)
2. **SSL/TLS**: Configurar certificados com cert-manager
3. **Backup**: Implementar Velero para backup
4. **GitOps**: Configurar ArgoCD ou Flux
5. **Service Mesh**: Avaliar Istio ou Linkerd
6. **Observabilidade**: Implementar Prometheus + Grafana

## Referências

- [Azure AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
