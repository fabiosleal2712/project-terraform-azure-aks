# Migração AWS EKS → Azure AKS

Este documento descreve o processo de migração do projeto de AWS EKS para Azure AKS.

## 📋 Resumo das Mudanças

### Infraestrutura

| AWS | Azure | Equivalente |
|-----|-------|-------------|
| EKS | AKS | Kubernetes gerenciado |
| ECR | ACR | Container Registry |
| VPC | VNet | Rede virtual |
| Security Groups | NSG | Grupo de segurança de rede |
| IAM Roles | Managed Identity | Identidades gerenciadas |
| CloudWatch | Log Analytics | Logs e métricas |
| RDS | Azure Database | Banco de dados gerenciado |
| S3 | Blob Storage | Armazenamento de objetos |
| ELB | Load Balancer | Balanceador de carga |
| Route53 | Azure DNS | DNS gerenciado |

### Arquivos Modificados

#### Terraform Core
- ✅ `providers.tf` - Migrado de AWS para Azure providers
- ✅ `variables.tf` - Variáveis adaptadas para Azure
- ✅ `main.tf` - Resource Group e recursos principais
- ✅ `outputs.tf` - Outputs específicos do Azure

#### Novos Arquivos Terraform
- ✅ `network.tf` - VNet, Subnets, NSGs
- ✅ `aks.tf` - Cluster AKS e node pools
- ✅ `acr.tf` - Azure Container Registry
- ✅ `monitoring.tf` - Log Analytics e Application Insights

#### Scripts
- ✅ `scripts/deploy.sh` - Deploy automatizado para Azure
- ✅ `scripts/destroy.sh` - Destruição da infraestrutura
- ✅ `scripts/update-kubeconfig.sh` - Atualizar kubeconfig do AKS

#### Kubernetes
- ✅ `kubernetes/namespaces/` - Namespaces para organização
- ✅ `kubernetes/deployments/` - Deployments das aplicações
- ✅ `kubernetes/secrets/` - Secrets (exemplo)
- ✅ `kubernetes/ingress/` - Regras de ingress

#### Documentação
- ✅ `README.md` - Documentação principal
- ✅ `QUICKSTART.md` - Guia rápido de início
- ✅ `docs/DEPLOY_GUIDE.md` - Guia completo de deploy

## 🔄 Processo de Migração

### Fase 1: Preparação

1. **Backup dos Dados**
   ```bash
   # Exportar dados do RDS (AWS)
   pg_dump -h <rds-endpoint> -U <user> -d <database> > backup.sql
   
   # Upload para Azure Blob Storage
   az storage blob upload \
     --account-name <storage> \
     --container-name backups \
     --file backup.sql
   ```

2. **Inventário de Recursos**
   - Listar todos os recursos AWS atualmente em uso
   - Mapear para equivalentes Azure
   - Documentar dependências

3. **Configuração Azure**
   ```bash
   # Login no Azure
   az login
   
   # Selecionar subscription
   az account set --subscription "<subscription-id>"
   
   # Criar Service Principal para Terraform
   az ad sp create-for-rbac \
     --name "terraform-sp" \
     --role Contributor \
     --scopes /subscriptions/<subscription-id>
   ```

### Fase 2: Provisionar Infraestrutura Azure

1. **Configurar Terraform**
   ```bash
   # Copiar variáveis de exemplo
   cp terraform.tfvars.example terraform.tfvars
   
   # Editar com suas configurações
   nano terraform.tfvars
   ```

2. **Deploy da Infraestrutura**
   ```bash
   # Inicializar Terraform
   terraform init
   
   # Planejar mudanças
   terraform plan
   
   # Aplicar infraestrutura
   terraform apply
   ```

3. **Verificar Recursos Criados**
   ```bash
   # Listar recursos no Resource Group
   az resource list \
     --resource-group $(terraform output -raw resource_group_name) \
     --output table
   ```

### Fase 3: Migrar Imagens de Containers

1. **Exportar Imagens do ECR**
   ```bash
   # Login no ECR
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
   
   # Pull das imagens
   docker pull <account>.dkr.ecr.us-east-1.amazonaws.com/chat-api:latest
   docker pull <account>.dkr.ecr.us-east-1.amazonaws.com/diary-api:latest
   # ... outras imagens
   ```

2. **Push para ACR**
   ```bash
   # Login no ACR
   ACR_NAME=$(terraform output -raw acr_name)
   az acr login --name $ACR_NAME
   
   # Re-tag imagens
   docker tag <account>.dkr.ecr.us-east-1.amazonaws.com/chat-api:latest \
              $ACR_NAME.azurecr.io/chat-api:latest
   
   # Push para ACR
   docker push $ACR_NAME.azurecr.io/chat-api:latest
   ```

3. **Build Direto no ACR (Alternativa)**
   ```bash
   # Build direto do código fonte
   az acr build \
     --registry $ACR_NAME \
     --image chat-api:latest \
     -f nutri-veda/src/Chat/Chat.API/Dockerfile \
     ./nutri-veda
   ```

### Fase 4: Migrar Dados

1. **Provisionar Azure Database**
   ```bash
   # Criar Azure Database for PostgreSQL
   az postgres flexible-server create \
     --resource-group $(terraform output -raw resource_group_name) \
     --name nutriveda-db \
     --location brazilsouth \
     --admin-user dbadmin \
     --admin-password <strong-password> \
     --sku-name Standard_D2s_v3 \
     --storage-size 128 \
     --version 14
   ```

2. **Restaurar Backup**
   ```bash
   # Restaurar dados
   psql -h <azure-db-endpoint> -U dbadmin -d postgres < backup.sql
   ```

3. **Verificar Dados**
   ```bash
   # Conectar ao banco
   psql -h <azure-db-endpoint> -U dbadmin -d nutriveda
   
   # Verificar tabelas
   \dt
   
   # Verificar contagem de registros
   SELECT COUNT(*) FROM users;
   ```

### Fase 5: Deploy de Aplicações no AKS

1. **Conectar ao Cluster**
   ```bash
   # Obter credenciais
   az aks get-credentials \
     --resource-group $(terraform output -raw resource_group_name) \
     --name $(terraform output -raw aks_cluster_name)
   
   # Verificar conexão
   kubectl get nodes
   ```

2. **Configurar Secrets**
   ```bash
   # Criar secret com connection string
   kubectl create secret generic db-connection \
     --from-literal=connection-string="Server=<db-server>;..." \
     -n nutri-veda-dev
   ```

3. **Deploy das Aplicações**
   ```bash
   # Aplicar namespaces
   kubectl apply -f kubernetes/namespaces/
   
   # Aplicar deployments
   kubectl apply -f kubernetes/deployments/
   
   # Verificar status
   kubectl get pods -n nutri-veda-dev
   ```

### Fase 6: Configurar DNS e Load Balancer

1. **Obter IP Público**
   ```bash
   # IP do Load Balancer
   terraform output public_ip_address
   ```

2. **Configurar DNS**
   ```bash
   # Criar zona DNS
   az network dns zone create \
     --resource-group $(terraform output -raw resource_group_name) \
     --name nutriveda.com
   
   # Criar registro A
   az network dns record-set a add-record \
     --resource-group $(terraform output -raw resource_group_name) \
     --zone-name nutriveda.com \
     --record-set-name api \
     --ipv4-address $(terraform output -raw public_ip_address)
   ```

3. **Configurar Ingress**
   ```bash
   # Instalar NGINX Ingress Controller
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
   
   # Aplicar regras
   kubectl apply -f kubernetes/ingress/
   ```

### Fase 7: Testes

1. **Testes de Conectividade**
   ```bash
   # Testar pods
   kubectl run -it --rm debug --image=busybox --restart=Never -- sh
   # Dentro do pod:
   wget -O- http://chat-api-service
   ```

2. **Testes de Aplicação**
   ```bash
   # Port-forward para teste local
   kubectl port-forward svc/chat-api-service 8080:80 -n nutri-veda-dev
   
   # Testar endpoint
   curl http://localhost:8080/health
   ```

3. **Testes de Carga**
   ```bash
   # Instalar k6 ou Apache Bench
   ab -n 1000 -c 10 http://api.nutriveda.com/chat/health
   ```

### Fase 8: Monitoramento

1. **Configurar Application Insights**
   ```bash
   # Obter connection string
   terraform output application_insights_connection_string
   
   # Adicionar ao deployment
   kubectl set env deployment/chat-api \
     APPLICATIONINSIGHTS_CONNECTION_STRING="..." \
     -n nutri-veda-dev
   ```

2. **Configurar Alertas**
   ```bash
   # Criar alerta de CPU
   az monitor metrics alert create \
     --name cpu-alert \
     --resource-group $(terraform output -raw resource_group_name) \
     --scopes $(terraform output -raw aks_cluster_id) \
     --condition "avg Percentage CPU > 80" \
     --description "Alert when CPU exceeds 80%"
   ```

### Fase 9: Cutover

1. **Checklist Pré-Cutover**
   - [ ] Todas as aplicações deployadas e funcionando
   - [ ] Dados migrados e verificados
   - [ ] DNS configurado
   - [ ] Monitoramento ativo
   - [ ] Backups configurados
   - [ ] Equipe treinada
   - [ ] Plano de rollback documentado

2. **Executar Cutover**
   ```bash
   # Atualizar DNS para apontar para Azure
   # Monitorar logs e métricas
   kubectl logs -f deployment/chat-api -n nutri-veda-dev
   
   # Ver métricas em tempo real
   kubectl top pods -n nutri-veda-dev
   ```

3. **Validação Pós-Cutover**
   - Verificar todos os endpoints
   - Validar funcionalidades críticas
   - Confirmar latência aceitável
   - Monitorar erros

### Fase 10: Descomissionar AWS (após validação)

1. **Aguardar Período de Estabilização**
   - Recomendado: 2-4 semanas

2. **Backup Final AWS**
   ```bash
   # Backup final de dados
   # Exportar logs importantes
   # Documentar configurações
   ```

3. **Destruir Recursos AWS**
   ```bash
   # No diretório do projeto antigo
   terraform destroy
   
   # Verificar recursos órfãos
   aws resourcegroupstaggingapi get-resources
   ```

## 📊 Comparação de Custos

### Estimativa Mensal (Dev Environment)

| Serviço | AWS | Azure | Diferença |
|---------|-----|-------|-----------|
| Kubernetes | EKS: $73 | AKS: Grátis | -$73 |
| Nodes (2x D2s_v3) | ~$140 | ~$140 | $0 |
| Load Balancer | ~$16 | ~$18 | +$2 |
| Container Registry | ~$5 | ~$5 | $0 |
| Database | ~$50 | ~$55 | +$5 |
| Monitoring | ~$30 | ~$25 | -$5 |
| **Total** | **~$314** | **~$243** | **-$71 (-23%)** |

*Valores aproximados, podem variar conforme uso

## 🔍 Troubleshooting

### Problemas Comuns

1. **Erro ao conectar ao AKS**
   ```bash
   # Re-obter credenciais
   az aks get-credentials --resource-group <rg> --name <aks> --overwrite-existing
   ```

2. **Pods não conseguem pull de imagens**
   ```bash
   # Verificar role assignment
   az role assignment list --scope <acr-id>
   
   # Recriar se necessário
   terraform taint azurerm_role_assignment.aks_acr
   terraform apply
   ```

3. **Problemas de rede**
   ```bash
   # Verificar NSG rules
   az network nsg rule list --resource-group <rg> --nsg-name <nsg> --output table
   ```

## 📚 Recursos Adicionais

- [Azure Migration Center](https://azure.microsoft.com/migration/)
- [AWS to Azure Services Comparison](https://docs.microsoft.com/azure/architecture/aws-professional/services)
- [AKS Best Practices](https://docs.microsoft.com/azure/aks/best-practices)

## ✅ Checklist de Migração

- [ ] Backup completo dos dados AWS
- [ ] Infraestrutura Azure provisionada
- [ ] Imagens migradas para ACR
- [ ] Dados migrados e validados
- [ ] Aplicações deployadas no AKS
- [ ] DNS configurado
- [ ] Monitoramento ativo
- [ ] Testes de funcionalidade
- [ ] Testes de carga
- [ ] Documentação atualizada
- [ ] Equipe treinada
- [ ] Plano de rollback pronto
- [ ] Cutover executado
- [ ] Validação pós-migração
- [ ] AWS descomissionado

## 🆘 Suporte

Em caso de problemas durante a migração:
1. Consultar logs: `kubectl logs` e Azure Portal
2. Verificar documentação: `docs/`
3. Abrir issue no repositório
4. Contatar equipe de DevOps
