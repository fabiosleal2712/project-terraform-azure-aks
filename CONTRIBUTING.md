# Contribuindo para o Projeto Azure AKS

Obrigado por considerar contribuir para este projeto! Este documento fornece diretrizes para contribuições.

## 📋 Índice

- [Código de Conduta](#código-de-conduta)
- [Como Posso Contribuir?](#como-posso-contribuir)
- [Diretrizes de Desenvolvimento](#diretrizes-de-desenvolvimento)
- [Processo de Pull Request](#processo-de-pull-request)
- [Padrões de Código](#padrões-de-código)
- [Testes](#testes)
- [Documentação](#documentação)

## 🤝 Código de Conduta

Este projeto segue o [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/). Ao participar, você concorda em manter um ambiente respeitoso e inclusivo.

## 💡 Como Posso Contribuir?

### Reportando Bugs

Antes de criar um bug report:
- Verifique se o bug já não foi reportado
- Colete informações sobre o problema
- Forneça passos para reproduzir

**Template de Bug Report:**
```markdown
**Descrição do Bug:**
[Descrição clara do que aconteceu]

**Como Reproduzir:**
1. Execute '...'
2. Faça '...'
3. Veja o erro

**Comportamento Esperado:**
[O que você esperava que acontecesse]

**Ambiente:**
- OS: [ex: Ubuntu 22.04]
- Terraform: [ex: 1.5.0]
- Azure CLI: [ex: 2.50.0]

**Logs/Screenshots:**
[Cole logs relevantes ou screenshots]
```

### Sugerindo Melhorias

**Template de Feature Request:**
```markdown
**Problema a Resolver:**
[Descrição do problema que esta feature resolveria]

**Solução Proposta:**
[Descrição detalhada da solução]

**Alternativas Consideradas:**
[Outras abordagens que você considerou]

**Contexto Adicional:**
[Informações adicionais ou screenshots]
```

### Contribuindo com Código

1. **Fork** o repositório
2. **Clone** seu fork localmente
3. **Crie** uma branch para sua feature
4. **Faça** suas alterações
5. **Teste** suas mudanças
6. **Commit** com mensagens claras
7. **Push** para seu fork
8. **Abra** um Pull Request

## 🛠️ Diretrizes de Desenvolvimento

### Configuração do Ambiente

```bash
# Clone o repositório
git clone https://github.com/your-username/project-terraform-azure-aks.git
cd project-terraform-azure-aks

# Instalar ferramentas necessárias
# Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Validar instalações
terraform version
az version
kubectl version --client
```

### Estrutura de Branches

- `main` - Branch principal, sempre estável
- `develop` - Branch de desenvolvimento
- `feature/*` - Novas funcionalidades
- `bugfix/*` - Correções de bugs
- `hotfix/*` - Correções urgentes
- `docs/*` - Atualizações de documentação

### Convenções de Nomenclatura

**Branches:**
```
feature/add-prometheus-monitoring
bugfix/fix-acr-permissions
hotfix/critical-security-patch
docs/update-deployment-guide
```

**Commits:**
```
feat: adiciona suporte para Azure Service Mesh
fix: corrige permissões do ACR
docs: atualiza guia de deployment
refactor: simplifica configuração de rede
test: adiciona testes para módulo AKS
chore: atualiza versão do provider Azure
```

## 🔍 Processo de Pull Request

### Checklist Antes de Submeter

- [ ] Código segue os padrões do projeto
- [ ] Terraform validate passa sem erros
- [ ] Terraform fmt foi executado
- [ ] Documentação foi atualizada
- [ ] Testes foram adicionados/atualizados
- [ ] CHANGELOG.md foi atualizado
- [ ] Commit messages seguem convenções
- [ ] Branch está atualizada com main

### Template de Pull Request

```markdown
## Descrição

[Descrição clara das mudanças]

## Tipo de Mudança

- [ ] Bug fix (mudança que corrige um problema)
- [ ] Nova feature (mudança que adiciona funcionalidade)
- [ ] Breaking change (correção ou feature que causa mudança incompatível)
- [ ] Documentação

## Como Foi Testado?

[Descreva os testes realizados]

## Checklist

- [ ] Terraform validate passou
- [ ] Terraform fmt executado
- [ ] Documentação atualizada
- [ ] Testes passaram
- [ ] CHANGELOG atualizado

## Screenshots (se aplicável)

[Cole screenshots]

## Issues Relacionadas

Fecha #123
Relacionada a #456
```

### Revisão de Código

Todos os PRs passam por revisão:
- ✅ Código limpo e legível
- ✅ Segue padrões do Terraform
- ✅ Documentação adequada
- ✅ Sem secrets ou credentials hardcoded
- ✅ Testes adequados
- ✅ Performance considerada

## 📝 Padrões de Código

### Terraform

**Formatação:**
```bash
# Formatar todos os arquivos
terraform fmt -recursive

# Verificar formatação
terraform fmt -check -recursive
```

**Validação:**
```bash
terraform validate
```

**Boas Práticas:**

```hcl
# ✅ BOM - Usar variáveis
variable "location" {
  description = "Azure region"
  type        = string
  default     = "brazilsouth"
}

# ❌ RUIM - Hardcoded
resource "azurerm_resource_group" "main" {
  location = "brazilsouth"
}

# ✅ BOM - Tags consistentes
tags = merge(
  var.tags,
  {
    Environment = var.environment
  }
)

# ✅ BOM - Nomear recursos claramente
resource "azurerm_kubernetes_cluster" "main" {
  name = "${var.project_name}-${var.environment}-aks"
}

# ✅ BOM - Usar depends_on quando necessário
depends_on = [
  azurerm_role_assignment.aks_acr
]
```

### Kubernetes Manifests

**Formatação:**
```bash
# Validar manifests
kubectl apply --dry-run=client -f kubernetes/
```

**Boas Práticas:**

```yaml
# ✅ BOM - Resource limits
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"

# ✅ BOM - Health checks
livenessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 10

# ✅ BOM - Labels apropriadas
metadata:
  labels:
    app: chat-api
    environment: dev
    version: "1.0.0"
```

### Scripts Bash

**Boas Práticas:**

```bash
#!/bin/bash

# ✅ BOM - Fail fast
set -e

# ✅ BOM - Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# ✅ BOM - Funções para mensagens
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# ✅ BOM - Validar pré-requisitos
if ! command -v az &> /dev/null; then
    print_error "Azure CLI não encontrado"
    exit 1
fi

# ✅ BOM - Confirmações para ações destrutivas
read -p "Deseja continuar? (y/n) " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi
```

## 🧪 Testes

### Testes Terraform

```bash
# Validação
terraform init
terraform validate

# Plano
terraform plan

# Testes com terratest (futuro)
go test -v ./test/
```

### Testes Kubernetes

```bash
# Validar sintaxe
kubectl apply --dry-run=client -f kubernetes/

# Validar conectividade
kubectl run test --image=busybox --rm -it -- sh

# Testar endpoints
kubectl port-forward svc/chat-api 8080:80
curl http://localhost:8080/health
```

### Testes Manuais

Antes de submeter PR:

1. **Deploy Completo**
   ```bash
   ./scripts/deploy.sh dev
   ```

2. **Verificar Recursos**
   ```bash
   az resource list --resource-group <rg> --output table
   kubectl get all -A
   ```

3. **Testar Funcionalidades**
   ```bash
   # Testar auto-scaling
   kubectl scale deployment chat-api --replicas=5
   
   # Testar rollback
   kubectl rollout undo deployment/chat-api
   
   # Testar logs
   kubectl logs -f deployment/chat-api
   ```

4. **Cleanup**
   ```bash
   ./scripts/destroy.sh
   ```

## 📚 Documentação

### Atualizando Documentação

Ao adicionar features:
- Atualizar `README.md` se necessário
- Criar/atualizar guias em `docs/`
- Adicionar entrada no `CHANGELOG.md`
- Atualizar `PROJECT_SUMMARY.md`
- Adicionar comentários no código

### Estilo de Documentação

**Markdown:**
- Usar headers apropriados (H1, H2, H3)
- Incluir exemplos de código
- Adicionar emojis para melhor navegação
- Links para recursos externos
- Screenshots quando apropriado

**Comentários no Código:**
```hcl
# BOM - Comentário descritivo
# Log Analytics Workspace para centralizar logs do cluster
resource "azurerm_log_analytics_workspace" "main" {
  # ...
}

# BOM - Comentário de contexto
# Necessário para permitir AKS fazer pull de imagens do ACR
resource "azurerm_role_assignment" "aks_acr" {
  # ...
}
```

## 🎯 Áreas de Contribuição

### Alta Prioridade

- [ ] Implementar Application Gateway Ingress Controller
- [ ] Adicionar suporte para Azure Service Mesh
- [ ] Implementar GitOps (ArgoCD/Flux)
- [ ] Adicionar Azure Database for PostgreSQL
- [ ] Implementar backup com Velero

### Média Prioridade

- [ ] Adicionar Prometheus + Grafana
- [ ] Implementar cert-manager para SSL
- [ ] Adicionar Azure Key Vault CSI driver
- [ ] Implementar Azure Policy
- [ ] Adicionar suporte multi-region

### Baixa Prioridade

- [ ] Melhorar documentação
- [ ] Adicionar mais exemplos
- [ ] Otimizar custos
- [ ] Adicionar testes automatizados
- [ ] Melhorar scripts

## 🆘 Precisa de Ajuda?

- 📖 Leia a [documentação completa](README.md)
- 💬 Abra uma [Discussion](https://github.com/your-repo/discussions)
- 🐛 Reporte [Issues](https://github.com/your-repo/issues)
- 📧 Contate a equipe DevOps

## 📜 Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a mesma licença do projeto.

---

**Obrigado por contribuir! 🎉**

Suas contribuições ajudam a tornar este projeto melhor para todos.
