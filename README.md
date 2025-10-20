# Azure AKS Infrastructure with Terraform

Este repositório contém código Terraform para provisionar e gerenciar um cluster Azure Kubernetes Service (AKS) com todas as dependências necessárias.

## 🏗️ Arquitetura

A infraestrutura inclui:

- **Azure Kubernetes Service (AKS)**: Cluster Kubernetes gerenciado
- **Azure Container Registry (ACR)**: Registro privado de containers
- **Virtual Network**: Rede virtual com subnets isoladas
- **Network Security Groups**: Controle de tráfego de rede
- **Log Analytics Workspace**: Centralização de logs
- **Application Insights**: Monitoramento de aplicações
- **User Managed Identity**: Identidade gerenciada para o cluster
- **Public IP**: IP público estático para o Load Balancer

## 📋 Pré-requisitos

1. **Azure CLI** instalado e configurado:
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

2. **Terraform** >= 1.5.0:
   ```bash
   terraform version
   ```

3. **kubectl** para gerenciar o cluster:
   ```bash
   kubectl version --client
   ```

4. **Permissões necessárias no Azure**:
   - Contributor ou Owner na subscription
   - Permissões para criar Service Principals (se necessário)

## 🚀 Como Usar

### 1. Clone o repositório

```bash
git clone <repository-url>
cd project-terraform-azure-aks
```

### 2. Configure as variáveis

Copie o arquivo de exemplo e ajuste conforme necessário:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite o arquivo `terraform.tfvars` com suas configurações:

```hcl
project_name = "meuproject"
environment  = "dev"
location     = "brazilsouth"

aks_node_count = 2
aks_node_vm_size = "Standard_D2s_v3"
```

### 3. Inicialize o Terraform

```bash
terraform init
```

### 4. Planeje a infraestrutura

```bash
terraform plan
```

### 5. Aplique as mudanças

```bash
terraform apply
```

Digite `yes` quando solicitado para confirmar.

### 6. Conecte-se ao cluster

```bash
# Obter credenciais do cluster
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) \
                       --name $(terraform output -raw aks_cluster_name)

# Verificar nodes
kubectl get nodes

# Verificar namespaces
kubectl get namespaces
```

### 7. Login no ACR

```bash
az acr login --name $(terraform output -raw acr_name)
```

## 📁 Estrutura do Projeto

```
.
├── main.tf              # Resource Group e recursos principais
├── providers.tf         # Configuração dos providers
├── variables.tf         # Definição de variáveis
├── outputs.tf           # Outputs do Terraform
├── network.tf           # Recursos de rede (VNet, Subnets, NSG)
├── aks.tf              # Cluster AKS e node pools
├── acr.tf              # Azure Container Registry
├── monitoring.tf        # Log Analytics e Application Insights
├── terraform.tfvars.example  # Exemplo de variáveis
└── README.md           # Este arquivo
```

## 🔧 Configurações Principais

### Variáveis Importantes

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `project_name` | Nome do projeto | `myaksproject` |
| `environment` | Ambiente (dev/staging/prod) | `dev` |
| `location` | Região Azure | `brazilsouth` |
| `kubernetes_version` | Versão do Kubernetes | `1.28.3` |
| `aks_node_count` | Número de nodes | `2` |
| `aks_node_vm_size` | Tamanho da VM | `Standard_D2s_v3` |
| `aks_enable_auto_scaling` | Habilitar autoscaling | `true` |
| `aks_min_count` | Mínimo de nodes (autoscaling) | `1` |
| `aks_max_count` | Máximo de nodes (autoscaling) | `5` |
| `acr_sku` | SKU do ACR | `Standard` |

### Recursos Criados

1. **Resource Group**: `{project_name}-{environment}-rg`
2. **VNet**: `{project_name}-{environment}-vnet`
3. **AKS Cluster**: `{project_name}-{environment}-aks`
4. **ACR**: `{project_name}{environment}acr{random}`
5. **Log Analytics**: `{project_name}-{environment}-law`

## 🔐 Segurança

### Boas Práticas Implementadas

- ✅ **RBAC Habilitado**: Controle de acesso baseado em funções
- ✅ **Azure AD Integration**: Autenticação via Azure AD
- ✅ **Network Policies**: Políticas de rede Azure CNI
- ✅ **Private ACR**: Registro privado de containers
- ✅ **Managed Identity**: Identidade gerenciada para o cluster
- ✅ **Network Security Groups**: Controle de tráfego
- ✅ **Key Vault Integration**: Integração com Azure Key Vault

### Melhorias de Segurança Recomendadas

Para ambientes de produção:

1. **Restringir IPs permitidos**:
   ```hcl
   allowed_ip_ranges = ["203.0.113.0/24", "198.51.100.0/24"]
   ```

2. **Habilitar Private Cluster**:
   ```hcl
   private_cluster_enabled = true
   ```

3. **Usar Azure Policy**:
   ```hcl
   azure_policy_enabled = true
   ```

4. **Configurar Backup**:
   - Implementar Azure Backup para PVCs
   - Configurar disaster recovery

## 📊 Monitoramento

### Log Analytics

Todos os logs do cluster são enviados para o Log Analytics Workspace:

```bash
# Workspace ID
terraform output log_analytics_workspace_id
```

### Application Insights

Monitore suas aplicações:

```bash
# Connection String
terraform output application_insights_connection_string
```

### Queries Úteis (KQL)

```kusto
// Logs de containers com erro
ContainerLog
| where LogEntry contains "error"
| project TimeGenerated, Computer, ContainerID, LogEntry

// Uso de CPU por node
Perf
| where ObjectName == "K8SNode"
| where CounterName == "cpuUsageNanoCores"
| summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
```

## 🔄 CI/CD

### GitHub Actions

Exemplo de workflow para deploy:

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Plan
        run: terraform plan
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

## 🧹 Limpeza

Para destruir toda a infraestrutura:

```bash
terraform destroy
```

⚠️ **ATENÇÃO**: Este comando irá deletar TODOS os recursos criados.

## 📚 Recursos Adicionais

- [Documentação do AKS](https://docs.microsoft.com/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 🆘 Suporte

Para suporte, abra uma issue no GitHub ou entre em contato com a equipe de DevOps.

## 📈 Roadmap

- [ ] Implementar Application Gateway Ingress Controller
- [ ] Adicionar Azure Service Mesh
- [ ] Configurar GitOps com Flux/ArgoCD
- [ ] Implementar Velero para backup
- [ ] Adicionar políticas de segurança com OPA
- [ ] Configurar observabilidade completa (Prometheus/Grafana)
```
