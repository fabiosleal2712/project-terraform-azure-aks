# Estimativa de Custos - Azure AKS

## 📊 Ambiente de Desenvolvimento (Dev)

### Recursos Principais

| Recurso | Especificação | Custo Mensal (USD) | Notas |
|---------|---------------|-------------------|-------|
| **AKS Cluster** | Managed Control Plane | $0.00 | Gratuito no Azure |
| **Virtual Machines** | 2x Standard_D2s_v3 | $140.00 | 2 vCPUs, 8 GB RAM cada |
| **Load Balancer** | Standard | $18.26 | Inclui IP público estático |
| **Virtual Network** | VNet + Subnets | $0.00 | Sem custo adicional |
| **Network Security Groups** | NSG Rules | $0.00 | Sem custo adicional |
| **Azure Container Registry** | Standard | $20.00 | 100 GB storage incluído |
| **Log Analytics Workspace** | Pay-as-you-go | $15.00 | ~5 GB/dia estimado |
| **Application Insights** | Basic | $10.00 | Incluído no workspace |
| **Managed Identity** | User Assigned | $0.00 | Sem custo adicional |
| **Azure Monitor** | Metrics + Alerts | $5.00 | 10 alertas estimados |
| **Bandwidth** | Data Transfer | $5.00 | ~50 GB/mês estimado |

**Total Ambiente Dev: ~$213/mês**

## 📊 Ambiente de Produção (Prod)

### Recursos Principais

| Recurso | Especificação | Custo Mensal (USD) | Notas |
|---------|---------------|-------------------|-------|
| **AKS Cluster** | Managed Control Plane | $0.00 | Gratuito no Azure |
| **Virtual Machines** | 3x Standard_D4s_v3 | $420.00 | 4 vCPUs, 16 GB RAM cada |
| **Virtual Machines (Workload)** | 2x Standard_D4s_v3 | $280.00 | Node pool adicional |
| **Load Balancer** | Standard | $18.26 | Inclui IP público estático |
| **Virtual Network** | VNet + Subnets | $0.00 | Sem custo adicional |
| **Network Security Groups** | NSG Rules | $0.00 | Sem custo adicional |
| **Azure Container Registry** | Premium | $165.00 | Geo-replication + 500 GB |
| **Log Analytics Workspace** | Pay-as-you-go | $50.00 | ~15 GB/dia estimado |
| **Application Insights** | Enterprise | $30.00 | Monitoramento avançado |
| **Managed Identity** | User Assigned | $0.00 | Sem custo adicional |
| **Azure Monitor** | Metrics + Alerts | $15.00 | 50 alertas estimados |
| **Bandwidth** | Data Transfer | $50.00 | ~500 GB/mês estimado |
| **Azure Backup** | VM Backups | $20.00 | Backup diário |
| **Azure Key Vault** | Standard | $5.00 | Gerenciamento de secrets |

**Total Ambiente Prod: ~$1,053/mês**

## 💰 Recursos Opcionais

### Banco de Dados

| Serviço | Especificação | Custo Mensal (USD) |
|---------|---------------|-------------------|
| **Azure Database PostgreSQL** | Flexible Server - Standard_D2s_v3 | $105.00 |
| **Azure Database PostgreSQL** | Flexible Server - Standard_D4s_v3 | $210.00 |
| **Azure SQL Database** | Standard S3 (100 DTU) | $150.00 |
| **Cosmos DB** | Serverless | Variável (~$50-200) |

### Storage

| Serviço | Especificação | Custo Mensal (USD) |
|---------|---------------|-------------------|
| **Blob Storage** | Hot Tier - 100 GB | $2.05 |
| **Azure Files** | Premium - 100 GB | $17.00 |
| **Managed Disks** | Premium SSD - 128 GB | $19.71 |

### Segurança e Compliance

| Serviço | Especificação | Custo Mensal (USD) |
|---------|---------------|-------------------|
| **Azure Defender for Kubernetes** | Por node | $15.00/node |
| **Azure Policy** | Compliance monitoring | Gratuito |
| **Azure Security Center** | Standard Tier | $15.00/node |
| **Azure Firewall** | Standard | $950.00 |
| **Application Gateway** | Standard v2 | $130.00 |

### Observabilidade Avançada

| Serviço | Especificação | Custo Mensal (USD) |
|---------|---------------|-------------------|
| **Grafana Managed** | Essential | $55.00 |
| **Prometheus Managed** | Free tier | $0.00 |
| **Azure Chaos Studio** | Por experimento | $1.00/hora |

## 📈 Otimizações de Custo

### 1. Reserved Instances (1 ano)
- **Economia**: 30-40% em VMs
- **Dev**: $140 → $98/mês (-$42)
- **Prod**: $700 → $490/mês (-$210)

### 2. Azure Hybrid Benefit
- **Economia**: Até 40% com licenças Windows Server
- Aplicável se usar Windows containers

### 3. Spot VMs
- **Economia**: Até 90% em workloads não críticos
- Ideal para ambientes de teste

### 4. Auto Scaling
- **Economia**: 20-30% ajustando capacidade
- Escalar para 1 node fora do horário comercial

### 5. Storage Tier Optimization
- **Economia**: 50% movendo para Cool/Archive
- Aplicar lifecycle policies

## 🎯 Cenários de Custo

### Startup (Minimal)
```
- AKS: 1 node Standard_B2s ($30)
- ACR Basic ($5)
- Log Analytics ($10)
Total: ~$45/mês
```

### Small Business (Desenvolvimento)
```
- AKS: 2 nodes Standard_D2s_v3 ($140)
- ACR Standard ($20)
- PostgreSQL Basic ($50)
- Log Analytics ($15)
- Monitoring ($10)
Total: ~$235/mês
```

### Medium Business (Produção)
```
- AKS: 3 nodes Standard_D4s_v3 ($420)
- ACR Premium ($165)
- PostgreSQL Standard ($210)
- Log Analytics ($50)
- Full Monitoring ($45)
- Backups ($20)
Total: ~$910/mês
```

### Enterprise (Alta Disponibilidade)
```
- AKS: 5+ nodes Standard_D8s_v3 ($1,400)
- ACR Premium com geo-replication ($165)
- PostgreSQL HA ($420)
- Full observability stack ($150)
- Security (Defender + Firewall) ($1,000)
- Application Gateway ($130)
Total: ~$3,265/mês
```

## 📉 Comparação AWS vs Azure

### Ambiente Equivalente (Dev)

| Categoria | AWS | Azure | Diferença |
|-----------|-----|-------|-----------|
| Kubernetes Control Plane | EKS: $73 | AKS: $0 | -$73 ✅ |
| Compute (2 nodes) | EC2: $140 | VM: $140 | $0 |
| Container Registry | ECR: $5 | ACR: $20 | +$15 |
| Load Balancer | ELB: $16 | LB: $18 | +$2 |
| Monitoring | CloudWatch: $30 | Monitor: $25 | -$5 ✅ |
| **Total** | **$264** | **$203** | **-$61 (-23%)** ✅ |

## 🔍 Calculadora de Custos

Use a calculadora oficial da Microsoft:
- https://azure.microsoft.com/pricing/calculator/

### Exemplo de Configuração

1. Adicionar "Azure Kubernetes Service"
2. Adicionar "Virtual Machines" (node pools)
3. Adicionar "Container Registry"
4. Adicionar "Log Analytics"
5. Adicionar "Load Balancer"
6. Revisar estimativa total

## 💡 Dicas para Reduzir Custos

### 1. Monitoramento Contínuo
```bash
# Ver custos atuais
az consumption usage list --output table

# Configurar alertas de budget
az consumption budget create \
  --budget-name monthly-limit \
  --amount 500 \
  --time-grain Monthly
```

### 2. Tagging Apropriado
```hcl
tags = {
  Environment = "dev"
  CostCenter  = "engineering"
  Project     = "nutriveda"
}
```

### 3. Auto-shutdown
```bash
# Desligar ambiente dev à noite
kubectl scale deployment --all --replicas=0 -n nutri-veda-dev
```

### 4. Right-sizing
```bash
# Analisar uso de recursos
kubectl top nodes
kubectl top pods -A

# Ajustar VM sizes conforme necessário
```

### 5. Usar Azure Advisor
```bash
# Obter recomendações de custo
az advisor recommendation list \
  --category Cost \
  --output table
```

## 📧 Alertas de Custo Recomendados

1. **Alerta 80%**: Quando atingir 80% do budget
2. **Alerta 100%**: Quando atingir 100% do budget
3. **Alerta Anomalia**: Para gastos inesperados
4. **Relatório Mensal**: Envio automático de relatório

## 🔗 Recursos Úteis

- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Cost Management](https://azure.microsoft.com/services/cost-management/)
- [Azure Advisor](https://azure.microsoft.com/services/advisor/)
- [Azure Reserved VM Instances](https://azure.microsoft.com/pricing/reserved-vm-instances/)

---

**Nota**: Todos os preços são estimativas baseadas na região Brazil South e estão sujeitos a alterações. Consulte sempre a calculadora oficial do Azure para preços atualizados.

**Última atualização**: Outubro 2025
