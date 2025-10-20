# Guia de Implementação (do zero até o EKS funcionando)

Ambiente alvo: Linux (Arch), OpenTofu 1.10.x, AWS CLI v2, kubectl, EKS 1.30

Este guia documenta exatamente o que foi feito neste repositório para sair do zero até um cluster EKS funcional com RDS Postgres e um fluxo de deploy local de imagens (sem push no ECR).

## 1) Pré-requisitos e setup local

- Instale:
  - OpenTofu 1.10.x
  - AWS CLI v2 (com Session Manager Plugin)
  - kubectl (cliente 1.30–1.34; pode mostrar warning de skew mas funciona)

- Configure credenciais AWS (perfil `default`) com acesso a IAM/EKS/EC2/VPC/RDS/ECR/SSM.

- Copie `terraform.tfvars.example` para `terraform.tfvars` e ajuste:
  - `cluster_name`, `instance_type`
  - `principal_arn` (ARN do usuário/role que administrará o EKS)
  - `db_password` (senha do Postgres)

Boas práticas aplicadas no repo:

- `versions.tf` fixa versões de providers (`aws ~> 5`, `kubernetes ~> 2`).
- `provider.tf` sem credenciais em texto; usa perfil do AWS CLI.
- `.gitignore` inclui `terraform.tfvars` e artefatos sensíveis.

## 2) Provisionamento da infraestrutura com OpenTofu

1. Inicialize e valide o plano:

  ```sh
  tofu init -upgrade
  tofu plan
  ```

1. Aplique:

  ```sh
  tofu apply
  ```

Componentes criados:

- VPC com subnets públicas e privadas, Internet Gateway e rota `0.0.0.0/0` para públicas.
- Tags nas subnets públicas para ELB/EKS e `map_public_ip_on_launch=true`.
- Security Groups: `main` (laboratório) e um SG dedicado ao RDS (porta 5432).
- EKS 1.30 com `access_config.authentication_mode = API_AND_CONFIG_MAP` (suporte a Access Entries v2).
- IAM Roles do cluster e dos nós. Para os nós, anexamos políticas padrão + `AmazonSSMManagedInstanceCore`.
- Managed Node Group (t3.micro). Ajustado para `desired=2` para evitar saturação de pods.
  - Em momento posterior, escalamos para `desired=3` e `max=3` para liberar capacidade quando o scheduler acusou "Too many pods".
- RDS PostgreSQL 16 (usuário `postgres`, DB `mydb`).
- Repositórios ECR por microserviço.

Problemas resolvidos no caminho:

- Duplicidade de IAM Role (importamos/ajustamos o recurso gerenciado).
- NodeGroup falhando por IP público: ativamos IGW, rota pública e `map_public_ip_on_launch` nas subnets.
- kubectl sem acesso: configuramos `aws_eks_access_entry` + `AmazonEKSClusterAdminPolicy` para o `principal_arn` correto.
- RDS em rede errada: unificamos SG vindo do módulo da VPC, migramos de MySQL para Postgres 16 e recriamos a instância.
- Capacidade de scheduling: aumentamos o Node Group quando o describe do pod mostrou `Too many pods`.

## 3) Conectividade com o cluster Kubernetes

- Atualize kubeconfig via AWS CLI (aws eks update-kubeconfig) e valide:

  ```sh
  kubectl get nodes
  ```

  Deve listar pelo menos 1–2 nós `Ready`.

## 4) Kubernetes: namespace e smoke test

- Namespace:

  ```sh
  kubectl apply -f k8s/namespace.yaml
  ```

- Smoke test com NGINX (inclui requests/limits e armazenamento efêmero):

  ```sh
  kubectl apply -f k8s/nginx-smoke.yaml
  kubectl -n nutri-veda rollout status deploy/nginx-smoke
  ```

- Se ficar `Pending` por falta de capacidade, aumente o Node Group (já deixamos `desired=2`).

## 5) RDS Postgres: endpoint e Secret de conexão

- O endpoint está em `tofu output -raw rds_endpoint` e também foi salvo em `nutri-veda/DB_ENDPOINT.txt`.
- Gere a Secret `db-conn` no cluster com o script:

  ```sh
  DB_NAME=mydb DB_USER=postgres DB_PASSWORD='...'
  ./scripts/apply-db-secret.sh nutri-veda
  ```

  O script detecta `DB_HOST` automaticamente a partir do output do OpenTofu e monta a connection string (SSL habilitado).

## 6) Deploy de microserviço sem push em registry

- Dockerfile de exemplo para `Chat.Api` em `nutri-veda/src/Chat/Chat.Api/Dockerfile` (multi-stage, .NET 9).
- Manifest pronto em `k8s/chat-api.yaml` (usa `image: chat-api:1.0.0` e `imagePullPolicy: Never`).
- Fluxo para carregar a imagem local em um nó do EKS via SSM + URL pré-assinada do S3:

  ```sh
  # 1) Build local (contexto na raiz do repo nutri-veda)
  docker build -t chat-api:1.0.0 -f nutri-veda/src/Chat/Chat.Api/Dockerfile nutri-veda

  # 2) Secret do DB (se ainda não aplicou)
  DB_NAME=mydb DB_USER=postgres DB_PASSWORD='...' ./scripts/apply-db-secret.sh nutri-veda

  # 3) Apply dos manifests do serviço
  kubectl apply -f k8s/chat-api.yaml -n nutri-veda

  # 4) Carregar imagem no nó (requer um bucket S3; defina BUCKET_TEMP)
  export BUCKET_TEMP=seu-bucket-temporario
  ./scripts/load-image-to-eks-node.sh my-test-cluster nutri-veda app=chat-api chat-api 1.0.0

  # 5) Reinicie o pod para usar a imagem local
  kubectl -n nutri-veda delete pod -l app=chat-api
  kubectl -n nutri-veda rollout status deploy/chat-api
  ```

Observação: o script faz `docker save`, envia para S3, gera URL pré-assinada, baixa no nó (via SSM) e importa no containerd.

Atualização importante: corrigimos o `scripts/load-image-to-eks-node.sh` para evitar erro ao passar `--parameters` no `aws ssm send-command`.
Agora o script usa um arquivo JSON temporário com os comandos e espera o status do SSM até `Success` (com timeout e mensagens claras).

## 7) Exposição externa (opcional)

- Instale o AWS Load Balancer Controller (IAM + Helm) e aplique um Ingress (modelo em `k8s/ingress-template.yaml`).
- Alternativa rápida sem ALB: port-forward local:

  ```sh
  kubectl -n nutri-veda port-forward svc/chat-api 8080:80
  ```

## 8) Observabilidade (planejado para reativar)

- Módulos `prometheus/` e `grafana/` existem e podem ser reativados quando os serviços estiverem estáveis.

## 9) Segurança e boas práticas

- Não versione segredos. Um arquivo `.env` com credenciais foi encontrado no repo do app — remova do git e rotacione tudo (inclui token GitHub).
- Use Kubernetes Secrets e/ou AWS Secrets Manager (já presente) para credenciais.
- Mantenha versões de providers pinadas e roles com menor privilégio necessário.

## 10) Troubleshooting comum

- Pod `Pending`: verifique `kubectl describe pod` (capacidade/taints/requests de storage efêmero).
- Nó sem Internet: confira IGW, route table pública e `map_public_ip_on_launch` nas subnets públicas.
- kubectl sem acesso: confira Access Entry do EKS (v2) e `aws eks update-kubeconfig`.
- Conexão RDS: verifique SG/portas, usuário `postgres`, DB `mydb`, e `SSL Mode=Require`.
- CreateContainerConfigError (secret not found): aplique `./scripts/apply-db-secret.sh` e reinicie o pod.
