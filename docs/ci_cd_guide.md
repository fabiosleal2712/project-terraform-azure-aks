# Guia de CI/CD

Este guia sugere uma pipeline com GitHub Actions usando OpenID Connect (OIDC) para autenticar na AWS sem chaves long-lived.

## Recomendações

- Use OIDC do GitHub para assumir uma role na AWS (sem secrets estáticos).
- Padronize com OpenTofu no CI (compatível com Terraform).
- Separe estágios: fmt/validate → plan (com artifact do plano) → apply (com aprovação manual).

## Etapas típicas

1) Checkout e setup
2) Configurar credenciais AWS via OIDC (role com políticas mínimas para operar recursos deste repo)
3) OpenTofu init/validate/plan
4) Aprovação manual e apply

## Exemplo (pseudo-workflow)

```yaml
name: infra

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  plan:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>
          aws-region: us-east-1
      - name: Setup tofu
        uses: opentofu/setup-opentofu@v1
        with:
          tofu_version: 1.10.0
      - name: Init
        run: tofu init -upgrade
      - name: Validate
        run: tofu validate
      - name: Plan
        run: tofu plan -out=tfplan
      - name: Upload plan
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: tfplan

  apply:
    needs: plan
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>
          aws-region: us-east-1
      - name: Setup tofu
        uses: opentofu/setup-opentofu@v1
        with:
          tofu_version: 1.10.0
      - name: Download plan
        uses: actions/download-artifact@v4
        with:
          name: tfplan
          path: .
      - name: Apply
        run: tofu apply -auto-approve tfplan
```

Observações:

- Armazene variáveis sensíveis fora do repositório (ex.: AWS Secrets Manager, repositórios privados de vars, etc.).
- Não commite `terraform.tfvars`; use variables de ambiente/secret managers.
- Para publicar imagens de microserviços, crie um job separado que faça build/push para o ECR (se optar por registry em vez de fluxo local).

## Publicação de imagens (opcional: ECR)

Se quiser abandonar o fluxo de imagens locais em nós, use ECR:

```sh
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker build -t chat-api:1.0.0 -f nutri-veda/src/Chat/Chat.Api/Dockerfile nutri-veda
docker tag chat-api:1.0.0 <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/chat-api:1.0.0
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/chat-api:1.0.0
```

Depois, ajuste o `k8s/chat-api.yaml` para apontar para a imagem no ECR e altere `imagePullPolicy: IfNotPresent`.
