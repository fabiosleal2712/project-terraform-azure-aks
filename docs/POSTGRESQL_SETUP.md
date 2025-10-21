# 🗄️ Guia de Provisionamento do Azure PostgreSQL

Este guia explica como provisionar o Azure Database for PostgreSQL Flexible Server para o projeto Nutri-Veda.

---

## 📋 Pré-requisitos

- Terraform/OpenTofu instalado
- Azure CLI autenticado (`az login`)
- Infraestrutura AKS já provisionada

---

## 🚀 Provisionamento via Terraform

### Opção 1: Via Terraform (Recomendado)

#### 1. Descomente o arquivo database.tf

O arquivo `database.tf` já está criado, mas comentado por padrão. Para provisionar:

```bash
# O arquivo database.tf já contém toda a configuração
# Ele cria:
# - Subnet dedicada para PostgreSQL (10.0.3.0/24)
# - Private DNS Zone
# - PostgreSQL Flexible Server com VNet integration
```

#### 2. Defina a senha do administrador

**IMPORTANTE**: Nunca commite senhas no código!

```bash
# Opção A: Variável de ambiente (recomendado)
export TF_VAR_db_admin_password="SuaSenhaForte123!@#"

# Opção B: Edite terraform.tfvars (NÃO COMMITE!)
# Descomente e ajuste:
# db_admin_password = "SuaSenhaForte123!@#"

# Opção C: Prompt interativo
# terraform apply (vai solicitar a senha)
```

**Requisitos da senha**:
- Mínimo 8 caracteres
- Pelo menos 1 letra maiúscula
- Pelo menos 1 letra minúscula
- Pelo menos 1 número
- Pelo menos 1 caractere especial

#### 3. Execute o Terraform

```bash
# Plan para ver o que será criado
tofu plan -out=tfplan

# Apply para provisionar
tofu apply tfplan
```

**Recursos que serão criados**:
- `azurerm_subnet.database` - Subnet 10.0.3.0/24
- `azurerm_private_dns_zone.postgres` - DNS privado
- `azurerm_private_dns_zone_virtual_network_link.postgres` - Link VNet
- `azurerm_postgresql_flexible_server.default` - Servidor PostgreSQL
- `azurerm_postgresql_flexible_server_database.default` - Database
- `azurerm_postgresql_flexible_server_firewall_rule` - Regra de firewall
- `azurerm_postgresql_flexible_server_configuration` (2x) - Configurações

#### 4. Obtenha a connection string

Após o provisionamento:

```bash
# Ver outputs
tofu output

# Connection string (sem senha)
tofu output postgres_connection_string

# Connection string completa (com senha) - CUIDADO!
tofu output -raw postgres_connection_string_full
```

---

### Opção 2: Via Azure CLI (Manual)

Se preferir provisionar manualmente:

```bash
# 1. Definir variáveis
RG="nutri-veda-dev-rg"
LOCATION="brazilsouth"
SERVER_NAME="nutri-veda-dev-postgres"
ADMIN_USER="psqladmin"
ADMIN_PASS="SuaSenhaForte123!@#"
DB_NAME="nutrivedadb"
VNET_NAME="nutri-veda-dev-vnet"
SUBNET_NAME="database-subnet"

# 2. Criar subnet para PostgreSQL (se não existir)
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --address-prefixes 10.0.3.0/24 \
  --delegations Microsoft.DBforPostgreSQL/flexibleServers

# 3. Criar Private DNS Zone
az network private-dns zone create \
  --resource-group $RG \
  --name privatelink.postgres.database.azure.com

# 4. Linkar DNS zone com VNet
az network private-dns link vnet create \
  --resource-group $RG \
  --zone-name privatelink.postgres.database.azure.com \
  --name postgres-vnet-link \
  --virtual-network $VNET_NAME \
  --registration-enabled false

# 5. Obter ID da subnet
SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --query id -o tsv)

# 6. Obter ID da DNS zone
DNS_ZONE_ID=$(az network private-dns zone show \
  --resource-group $RG \
  --name privatelink.postgres.database.azure.com \
  --query id -o tsv)

# 7. Criar PostgreSQL Flexible Server
az postgres flexible-server create \
  --resource-group $RG \
  --name $SERVER_NAME \
  --location $LOCATION \
  --admin-user $ADMIN_USER \
  --admin-password "$ADMIN_PASS" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 16 \
  --subnet $SUBNET_ID \
  --private-dns-zone $DNS_ZONE_ID \
  --backup-retention 7

# 8. Criar database
az postgres flexible-server db create \
  --resource-group $RG \
  --server-name $SERVER_NAME \
  --database-name $DB_NAME

# 9. Configurar extensões
az postgres flexible-server parameter set \
  --resource-group $RG \
  --server-name $SERVER_NAME \
  --name azure.extensions \
  --value UUID-OSSP,PGCRYPTO

# 10. Configurar timezone
az postgres flexible-server parameter set \
  --resource-group $RG \
  --server-name $SERVER_NAME \
  --name timezone \
  --value "America/Sao_Paulo"
```

---

## 🔧 Atualizar Secret no Kubernetes

Após provisionar o PostgreSQL, atualize o secret:

```bash
# 1. Obter FQDN do servidor
POSTGRES_FQDN=$(tofu output -raw postgres_server_fqdn)
# Ou manualmente:
# POSTGRES_FQDN="nutri-veda-dev-postgres.postgres.database.azure.com"

# 2. Montar connection string
CONNECTION_STRING="Host=${POSTGRES_FQDN};Database=nutrivedadb;Username=psqladmin;Password=SuaSenhaForte123!@#;SSL Mode=Require"

# 3. Deletar secret antigo
kubectl delete secret db-connection -n nutri-veda-dev

# 4. Criar novo secret
kubectl create secret generic db-connection -n nutri-veda-dev \
  --from-literal=connection-string="$CONNECTION_STRING" \
  --from-literal=username="psqladmin" \
  --from-literal=password="SuaSenhaForte123!@#"

# 5. Verificar
kubectl describe secret db-connection -n nutri-veda-dev
```

---

## 🔄 Reiniciar Pods

Após atualizar o secret, reinicie os deployments:

```bash
# Restart do chat-api
kubectl rollout restart deployment/chat-api -n nutri-veda-dev

# Verificar pods
kubectl get pods -n nutri-veda-dev -w

# Ver logs
kubectl logs -f -n nutri-veda-dev -l app=chat-api
```

---

## 🧪 Testar Conexão

### Via kubectl port-forward

```bash
# 1. Port-forward do PostgreSQL (se houver algum pod conectado)
# Não é possível fazer port-forward direto do PostgreSQL no VNet privado

# 2. Criar um pod de teste
kubectl run -it --rm postgres-test --image=postgres:16 -n nutri-veda-dev -- bash

# 3. Dentro do pod, conectar ao PostgreSQL
psql "host=nutri-veda-dev-postgres.postgres.database.azure.com port=5432 dbname=nutrivedadb user=psqladmin sslmode=require"

# 4. Testar queries
\l              # Listar databases
\dt             # Listar tabelas
\q              # Sair
```

### Via Azure Cloud Shell

```bash
# 1. Abrir Cloud Shell
az cloud-shell

# 2. Conectar ao PostgreSQL
psql "host=nutri-veda-dev-postgres.postgres.database.azure.com port=5432 dbname=nutrivedadb user=psqladmin sslmode=require"
```

---

## 📊 Executar Migrations

Dependendo da aplicação, você pode precisar executar migrations:

### Via kubectl exec

```bash
# 1. Criar um Job de migrations (se tiver Dockerfile.migrations.api)
kubectl apply -f k8s/migrations-job.yaml

# 2. Acompanhar logs
kubectl logs -f job/migrations -n nutri-veda-dev
```

### Via Azure Container Instances (temporário)

```bash
# 1. Build da imagem de migrations
docker build -t nutrivedadevacr204ff1.azurecr.io/migrations:v1.0 \
  -f Dockerfile.migrations.api .

# 2. Push
docker push nutrivedadevacr204ff1.azurecr.io/migrations:v1.0

# 3. Executar via ACI
az container create \
  --resource-group nutri-veda-dev-rg \
  --name migrations-run \
  --image nutrivedadevacr204ff1.azurecr.io/migrations:v1.0 \
  --restart-policy Never \
  --environment-variables \
    ConnectionStrings__DefaultConnection="$CONNECTION_STRING"

# 4. Ver logs
az container logs -g nutri-veda-dev-rg -n migrations-run

# 5. Deletar
az container delete -g nutri-veda-dev-rg -n migrations-run --yes
```

---

## 💰 Custos Estimados

### Tier Burstable (Desenvolvimento)
- **SKU**: B_Standard_B1ms
- **Specs**: 1 vCore, 2 GB RAM, 32 GB storage
- **Custo**: ~$15-20/mês
- **Uso**: Dev/Test

### Tier General Purpose (Produção)
- **SKU**: GP_Standard_D2s_v3
- **Specs**: 2 vCores, 8 GB RAM, 128 GB storage
- **Custo**: ~$120-150/mês
- **Uso**: Produção

### Alta Disponibilidade
- **Adicional**: +100% do custo do servidor
- **Benefício**: Zone-redundant com failover automático

---

## 🔒 Segurança

### VNet Integration (Aplicado)
- ✅ PostgreSQL na subnet privada
- ✅ Sem acesso público à internet
- ✅ Apenas AKS pode acessar via VNet

### Firewall Rules
- ✅ Regra "AllowAzureServices" para permitir serviços Azure
- ⚠️ Não há acesso público direto

### SSL/TLS
- ✅ SSL obrigatório (SSL Mode=Require)
- ✅ Certificados gerenciados pelo Azure

### Backup
- ✅ Backup automático diário
- ✅ Retenção: 7 dias (configurável)
- ⚠️ Geo-redundância desabilitada (economia)

---

## 🛠️ Troubleshooting

### Erro: "Connection refused"
```bash
# Verificar se o servidor está ativo
az postgres flexible-server show -g nutri-veda-dev-rg -n nutri-veda-dev-postgres

# Verificar conectividade da subnet
az network vnet subnet show \
  -g nutri-veda-dev-rg \
  --vnet-name nutri-veda-dev-vnet \
  -n database-subnet
```

### Erro: "SSL required"
```bash
# Sempre use sslmode=require na connection string
SSL Mode=Require
# ou
sslmode=require
```

### Erro: "Authentication failed"
```bash
# Verificar username e senha
# Username deve ser: psqladmin (sem @servername)
# Senha: mínimo 8 caracteres com complexidade
```

### Ver logs do PostgreSQL
```bash
az postgres flexible-server server-logs list \
  -g nutri-veda-dev-rg \
  -n nutri-veda-dev-postgres

az postgres flexible-server server-logs download \
  -g nutri-veda-dev-rg \
  -n nutri-veda-dev-postgres \
  -n <log-filename>
```

---

## 📚 Referências

- [Azure PostgreSQL Flexible Server Documentation](https://docs.microsoft.com/azure/postgresql/flexible-server/)
- [Connection Strings .NET](https://www.connectionstrings.com/postgresql/)
- [Npgsql - PostgreSQL provider for .NET](https://www.npgsql.org/)
- [PostgreSQL 16 Documentation](https://www.postgresql.org/docs/16/)

---

## ✅ Checklist de Provisionamento

- [ ] Definir senha forte para o administrador
- [ ] Executar `tofu plan` e revisar recursos
- [ ] Executar `tofu apply` e aguardar provisionamento (~10-15 min)
- [ ] Obter connection string dos outputs
- [ ] Atualizar secret `db-connection` no Kubernetes
- [ ] Reiniciar deployments
- [ ] Executar migrations (se necessário)
- [ ] Testar conexão via pod de teste
- [ ] Verificar logs das aplicações
- [ ] Configurar backups adicionais (se necessário)
- [ ] Documentar credenciais em local seguro (Azure Key Vault)

---

**Status**: Pronto para provisionamento 🚀
