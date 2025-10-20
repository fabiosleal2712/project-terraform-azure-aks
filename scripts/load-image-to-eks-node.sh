#!/usr/bin/env bash
set -euo pipefail

# Carrega uma imagem Docker local para o node do EKS via SSM (sem push no registry)
# Requisitos:
# - AWS CLI v2
# - Session Manager Plugin (session-manager-plugin)
# - kubectl
# - jq
# - A role dos nós com política AmazonSSMManagedInstanceCore
# Uso:
#   ./load-image-to-eks-node.sh <cluster-name> <namespace> <pod-selector> <local-image> <tag>
#   Requer também a variável BUCKET_TEMP (S3) configurada no ambiente.
# Exemplo:
#   BUCKET_TEMP=meu-bucket-temporario \
#   ./load-image-to-eks-node.sh my-test-cluster nutri-veda app=chat-api chat-api 1.0.0

if [ "$#" -ne 5 ]; then
  echo "Uso: $0 <cluster-name> <namespace> <pod-selector> <local-image> <tag>" >&2
  exit 1
fi

CLUSTER_NAME="$1"
NAMESPACE="$2"
SELECTOR="$3"    # ex: app=chat-api
LOCAL_IMAGE="$4"  # ex: chat-api
TAG="$5"          # ex: 1.0.0

# 1) Descobre o node onde um pod do selector está rodando
POD=$(kubectl -n "$NAMESPACE" get pods -l "$SELECTOR" -o json | jq -r '.items[0].metadata.name')
if [ -z "$POD" ] || [ "$POD" = "null" ]; then
  echo "Nenhum pod encontrado para selector $SELECTOR em $NAMESPACE. Aplique o deployment antes." >&2
  exit 1
fi
NODE=$(kubectl -n "$NAMESPACE" get pod "$POD" -o json | jq -r '.spec.nodeName')
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=private-dns-name,Values=$NODE" --query 'Reservations[0].Instances[0].InstanceId' --output text)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "None" ]; then
  echo "Não foi possível mapear node $NODE para InstanceId EC2." >&2
  exit 1
fi

echo "Carregando imagem local $LOCAL_IMAGE:$TAG no node $NODE ($INSTANCE_ID) via SSM..."

# 2) Exporta a imagem local para tar
TMP_TAR=$(mktemp /tmp/image-XXXXXX.tar)
docker save "$LOCAL_IMAGE:$TAG" -o "$TMP_TAR"

# 3) Upload para S3 e gerar URL pré-assinada (nó fará download via curl, sem precisar de IAM/S3/CLI no nó)
if [ -z "${BUCKET_TEMP:-}" ]; then
  echo "Defina BUCKET_TEMP com um bucket S3 no qual você tenha permissão de upload." >&2
  exit 1
fi

KEY="eks-image-load/$(date +%s)-$(basename "$TMP_TAR")"
aws s3 cp "$TMP_TAR" "s3://$BUCKET_TEMP/$KEY"
URL=$(aws s3 presign "s3://$BUCKET_TEMP/$KEY" --expires-in 900)
if [ -z "$URL" ]; then
  echo "Falha ao gerar URL pré-assinada para s3://$BUCKET_TEMP/$KEY" >&2
  exit 1
fi

# 4) Baixar no node (curl) e carregar no containerd
#    Use um arquivo JSON para evitar problemas de escape/parsing no CLI
PARAMS_FILE=$(mktemp /tmp/ssm-params-XXXXXX.json)
cat > "$PARAMS_FILE" <<EOF
{
  "commands": [
    "sudo mkdir -p /tmp/eks-image",
    "sudo curl -L \"$URL\" -o /tmp/eks-image/img.tar",
    "sudo ctr -n k8s.io images import /tmp/eks-image/img.tar",
    "sudo ctr -n k8s.io images tag docker.io/library/$LOCAL_IMAGE:$TAG $LOCAL_IMAGE:$TAG"
  ]
}
EOF

CMD_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Load image tar into containerd" \
  --parameters file://"$PARAMS_FILE" \
  --query 'Command.CommandId' --output text)

echo "Comando SSM enviado (CommandId: $CMD_ID). Aguardando conclusão..."

# 5) Espera pelo término do comando
STATUS=""
for i in {1..60}; do
  STATUS=$(aws ssm get-command-invocation \
    --command-id "$CMD_ID" \
    --instance-id "$INSTANCE_ID" \
    --query 'Status' --output text || true)
  echo "SSM status: $STATUS"
  if [ "$STATUS" = "Success" ]; then
    break
  fi
  if [ "$STATUS" = "Failed" ] || [ "$STATUS" = "Cancelled" ] || [ "$STATUS" = "TimedOut" ]; then
    echo "Falha ao executar comando no SSM (Status: $STATUS). Consulte os logs no AWS Systems Manager." >&2
    exit 1
  fi
  sleep 5
done

if [ "$STATUS" != "Success" ]; then
  echo "Tempo esgotado aguardando o SSM concluir. Verifique no console do Systems Manager." >&2
  exit 1
fi

echo "Imagem importada e taggeada no node. Agora reinicie o pod para usar a imagem local (imagePullPolicy: Never)."
