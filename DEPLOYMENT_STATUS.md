# 🚀 Status do Deployment - Nutri-Veda AKS

**Data**: 20 de Outubro de 2025  
**Cluster**: nutri-veda-dev-aks  
**Região**: brazilsouth (São Paulo)

---

## ✅ Infraestrutura Implantada

### Azure Resources
- ✅ **Resource Group**: nutri-veda-dev-rg
- ✅ **AKS Cluster**: nutri-veda-dev-aks (Kubernetes 1.31.11)
- ✅ **ACR**: nutrivedadevacr204ff1.azurecr.io
- ✅ **VNet**: 10.0.0.0/16
- ✅ **Log Analytics Workspace**: Monitoramento configurado
- ✅ **Application Insights**: Telemetria ativa
- ✅ **Managed Identity**: Configurada para AKS

### Cluster Status
- ✅ **Nodes**: 2/5 (auto-scaling ativo)
  - aks-default-90303446-vmss000000 (Ready)
  - aks-default-90303446-vmss000001 (Ready)
- ✅ **VM Size**: Standard_D2s_v6 (2 vCPU, 8 GB RAM)
- ✅ **ACR Integration**: Configurada (az aks update --attach-acr)

### Namespaces Criados
- ✅ nutri-veda-dev
- ✅ nutri-veda-staging
- ✅ nutri-veda-prod
- ✅ monitoring

---

## 🐳 Container Images

### Chat API
- ✅ **Build**: Sucesso
- ✅ **Push**: nutrivedadevacr204ff1.azurecr.io/chat-api:v1.0
- ✅ **Dockerfile**: Dockerfile.chat.api (corrigido)

### Outros Microserviços (Pendentes)
- ⏳ diary-api
- ⏳ users-api
- ⏳ migrations-api
- ⏳ schedulings-api
- ⏳ systemsettings-api
- ⏳ webapp
- ⏳ adm.dashboard.webapp

---

## ⚠️ Problemas Identificados e Soluções

### 1. Porta da Aplicação
**Problema**: A aplicação ASP.NET Core 9.0 está escutando na porta **8080**, não na porta 80.

**Solução Aplicada**:
```yaml
ports:
  - containerPort: 8080
env:
  - name: ASPNETCORE_URLS
    value: "http://+:8080"
```

### 2. Banco de Dados PostgreSQL
**Problema**: Aplicação tentando conectar ao PostgreSQL em `localhost:5432` (não existe).

**Solução Necessária**: 
- Provisionar Azure Database for PostgreSQL Flexible Server
- Atualizar a connection string no secret `db-connection`

**Comando para Criar PostgreSQL**:
```bash
az postgres flexible-server create \
  --resource-group nutri-veda-dev-rg \
  --name nutriveda-dev-postgres \
  --location brazilsouth \
  --admin-user nutriadmin \
  --admin-password '<senha-forte>' \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 16 \
  --public-access 0.0.0.0
```

**Atualizar Secret**:
```bash
kubectl delete secret db-connection -n nutri-veda-dev

kubectl create secret generic db-connection -n nutri-veda-dev \
  --from-literal=connection-string="Host=nutriveda-dev-postgres.postgres.database.azure.com;Database=nutrivedadb;Username=nutriadmin;Password=<senha>;SSL Mode=Require" \
  --from-literal=username="nutriadmin" \
  --from-literal=password="<senha>"
```

### 3. Health Checks
**Problema**: As rotas `/health` e `/ready` podem não existir na aplicação.

**Solução Temporária**: Comentar os probes ou ajustar para rotas existentes.

---

## 📝 Próximos Passos

### Fase 1: Banco de Dados (CRÍTICO)
1. ✅ Provisionar Azure Database for PostgreSQL Flexible Server
2. ✅ Configurar firewall rules para permitir acesso do AKS
3. ✅ Criar database `nutrivedadb`
4. ✅ Executar migrations
5. ✅ Atualizar secret `db-connection` com connection string real

### Fase 2: Correção do Chat API
1. ✅ Aplicar deployment atualizado (porta 8080)
   ```bash
   kubectl apply -f kubernetes/deployments/chat-api.yaml
   ```
2. ✅ Verificar logs
   ```bash
   kubectl logs -n nutri-veda-dev -l app=chat-api --tail=100
   ```
3. ✅ Testar endpoints
   ```bash
   kubectl port-forward -n nutri-veda-dev svc/chat-api-service 8080:80
   curl http://localhost:8080/health
   ```

### Fase 3: Build e Deploy dos Outros Microserviços
Para cada microserviço, seguir o padrão:

```bash
# 1. Corrigir Dockerfile (substituir niu-nutri por nutri-veda, comentar certificado)
# Exemplo para diary-api:
sed -i 's/niu-nutri/nutri-veda/g' Dockerfile.diary.api
sed -i 's/COPY aspnetapp.pfx/# COPY aspnetapp.pfx/g' Dockerfile.diary.api

# 2. Build
docker build -t nutrivedadevacr204ff1.azurecr.io/diary-api:v1.0 -f Dockerfile.diary.api .

# 3. Push
docker push nutrivedadevacr204ff1.azurecr.io/diary-api:v1.0

# 4. Criar deployment manifest (copiar e ajustar chat-api.yaml)

# 5. Deploy
kubectl apply -f kubernetes/deployments/diary-api.yaml
```

### Fase 4: Ingress Controller
1. Instalar NGINX Ingress Controller
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/cloud/deploy.yaml
   ```
2. Aguardar External IP
   ```bash
   kubectl get svc -n ingress-nginx
   ```
3. Aplicar Ingress manifest
   ```bash
   kubectl apply -f kubernetes/ingress/ingress.yaml
   ```

### Fase 5: CI/CD
1. Configurar GitHub Secrets:
   - `AZURE_CREDENTIALS`
   - `ACR_LOGIN_SERVER`: nutrivedadevacr204ff1.azurecr.io
   - `AKS_CLUSTER_NAME`: nutri-veda-dev-aks
   - `AKS_RESOURCE_GROUP`: nutri-veda-dev-rg
2. Testar workflow
   ```bash
   git add .
   git commit -m "Deploy to AKS"
   git push
   ```

### Fase 6: Monitoramento
1. Acessar Application Insights no portal
2. Configurar alertas
3. Revisar dashboards do Grafana (se aplicável)

---

## 🛠️ Comandos Úteis

### Verificar Status do Cluster
```bash
# Nodes
kubectl get nodes

# Pods em todos os namespaces
kubectl get pods --all-namespaces

# Pods no namespace dev
kubectl get pods -n nutri-veda-dev

# Descrever pod
kubectl describe pod -n nutri-veda-dev <pod-name>

# Logs
kubectl logs -n nutri-veda-dev <pod-name> -f
```

### Scale Deployments
```bash
# Manual scale
kubectl scale deployment chat-api -n nutri-veda-dev --replicas=3

# Verificar HPA (se configurado)
kubectl get hpa -n nutri-veda-dev
```

### Debugging
```bash
# Port-forward para testar serviço
kubectl port-forward -n nutri-veda-dev svc/chat-api-service 8080:80

# Exec into pod
kubectl exec -it -n nutri-veda-dev <pod-name> -- /bin/bash

# Verificar eventos
kubectl get events -n nutri-veda-dev --sort-by='.lastTimestamp'
```

### Rollback
```bash
# Ver histórico
kubectl rollout history deployment/chat-api -n nutri-veda-dev

# Rollback
kubectl rollout undo deployment/chat-api -n nutri-veda-dev
```

---

## 📊 Recursos e Custos Estimados

### Custos Mensais Estimados (Dev Environment)
- **AKS Control Plane**: Gratuito (Free tier)
- **Nodes (2x Standard_D2s_v6)**: ~$140/mês
- **ACR (Standard)**: ~$20/mês
- **Log Analytics**: ~$5-15/mês (depende do volume)
- **PostgreSQL (Standard_B1ms)**: ~$15/mês
- **Networking**: ~$5-10/mês

**Total Estimado**: ~$185-200/mês

### Otimizações de Custo
- Habilitar auto-scaling com min=1 node fora do horário comercial
- Usar Azure Reserved Instances para nodes (até 72% desconto)
- Configurar retention policies adequadas no Log Analytics

---

## 📚 Documentação de Referência

- [Documentação do Projeto](./docs/README.md)
- [Guia de Deployment](./docs/DEPLOY_GUIDE.md)
- [Guia de Migração](./docs/MIGRATION_GUIDE.md)
- [CI/CD Guide](./docs/ci_cd_guide.md)
- [Estimativa de Custos](./docs/COST_ESTIMATION.md)

---

## ✅ Checklist de Verificação

### Infraestrutura
- [x] Terraform/OpenTofu deployment bem-sucedido
- [x] AKS cluster operacional
- [x] ACR criado e integrado
- [x] Networking configurado
- [x] Monitoramento ativo
- [ ] PostgreSQL provisionado

### Aplicação
- [x] Dockerfiles corrigidos
- [x] Chat API image construída e enviada ao ACR
- [x] Namespaces criados
- [x] Secrets criados (temporários)
- [ ] Secrets atualizados com dados reais
- [ ] Health checks funcionando
- [ ] Todos os microserviços deployados

### Rede
- [ ] Ingress Controller instalado
- [ ] DNS configurado
- [ ] SSL/TLS configurado
- [ ] Network Policies aplicadas (se necessário)

### CI/CD
- [ ] GitHub Actions configurado
- [ ] Secrets do GitHub configurados
- [ ] Pipeline testado
- [ ] Blue-green ou canary deployment configurado

---

**Status Geral**: 🟡 **Em Progresso** (Infraestrutura completa, aplicação parcial)

**Próxima Ação Crítica**: Provisionar Azure PostgreSQL e atualizar connection string
