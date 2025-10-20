# Projeto Infra AWS com OpenTofu + EKS

Este repositório provisiona uma stack AWS moderna usando OpenTofu (compatível com Terraform):

- VPC com subnets públicas/privadas, IGW e rotas públicas
- EKS (Kubernetes 1.30) com Managed Node Group
- RDS PostgreSQL 16
- ECR por microserviço
- Secrets Manager e CDN (CloudFront)
- Manifests Kubernetes base e fluxo para carregar imagens locais no nó EKS (sem push no registry)

## Estrutura do Repositório

- Arquivos de IaC na raiz: `main.tf`, `variables.tf`, `versions.tf`, `provider.tf`, `outputs.tf`
- Módulos: `modules/` (vpc, eks, rds, ecr, etc.)
- Kubernetes: `k8s/` (namespace, templates de deployment/service/ingress, smoke test nginx)
- Scripts: `scripts/` (carga de imagem local via SSM + geração de Secret do DB)
- App exemplo: `nutri-veda/` (código .NET e Dockerfiles)
- Documentação: `docs/`

## Pré-requisitos

- OpenTofu 1.10.x
- AWS CLI v2 + Session Manager Plugin
- kubectl (cliente 1.30–1.34)
- Docker (para build de imagens locais)
- jq (usado pelos scripts)

## Como executar (resumo)

1) Configure credenciais AWS (perfil default) e `terraform.tfvars` conforme `terraform.tfvars.example` (defina cluster_name, principal_arn, senhas, etc.)
2) Provisionamento:
	- tofu init -upgrade
	- tofu plan
	- tofu apply
3) Configure e valide acesso ao EKS:
	- aws eks update-kubeconfig --region us-east-1 --name CLUSTER_NAME
	- kubectl get nodes
4) Kubernetes base:
	- kubectl apply -f k8s/namespace.yaml
	- kubectl apply -f k8s/nginx-smoke.yaml
	- kubectl -n nutri-veda rollout status deploy/nginx-smoke
5) RDS/Secret:
	- DB_NAME=mydb DB_USER=postgres DB_PASSWORD='...' ./scripts/apply-db-secret.sh nutri-veda
6) Deploy de serviço com imagem local (sem ECR):
	- docker build -t chat-api:1.0.0 -f PATH/TO/Dockerfile PATH/TO/CONTEXT
	- export BUCKET_TEMP=SEU_BUCKET_S3
	- kubectl apply -f k8s/chat-api.yaml -n nutri-veda
	- ./scripts/load-image-to-eks-node.sh CLUSTER_NAME nutri-veda app=chat-api chat-api 1.0.0
	- kubectl -n nutri-veda delete pod -l app=chat-api

Detalhes passo a passo no `implementation_guide.md` e `ci_cd_guide.md`.

## Dicas rápidas / Troubleshooting

- Pod Pending por capacidade: aumente o Node Group (desired/max) e reaplique com OpenTofu.
- ErrImageNeverPull: importe a imagem no nó com `scripts/load-image-to-eks-node.sh` e reinicie o pod.
- CreateContainerConfigError (secret not found): aplique a Secret `db-conn` com `scripts/apply-db-secret.sh`.
- Conectividade ao cluster: use `aws eks update-kubeconfig` e confirme Access Entries v2 (já configurado via IaC).
