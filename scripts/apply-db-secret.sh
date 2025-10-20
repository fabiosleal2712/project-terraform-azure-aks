#!/usr/bin/env bash
set -euo pipefail

# Gera e aplica a Secret de conexão com o Postgres no namespace informado.
# Usa variáveis de ambiente: DB_HOST (opcional), DB_NAME, DB_USER, DB_PASSWORD.
# Se DB_HOST não for definido, tenta obter do OpenTofu: rds_endpoint (host sem porta).
# Uso:
#   DB_NAME=... DB_USER=... DB_PASSWORD=... ./scripts/apply-db-secret.sh [namespace]
# Exemplo:
#   DB_NAME=nutriveda DB_USER=postgres DB_PASSWORD='s3nh@' ./scripts/apply-db-secret.sh nutri-veda

NAMESPACE="${1:-nutri-veda}"

DB_HOST="${DB_HOST:-}"
if [ -z "$DB_HOST" ]; then
  if command -v tofu >/dev/null 2>&1; then
    # Extrai apenas o host (antes dos dois-pontos)
    DB_HOST=$(tofu output -raw rds_endpoint | awk -F: '{print $1}') || true
  fi
fi

: "${DB_NAME:?Defina DB_NAME no ambiente}"
: "${DB_USER:?Defina DB_USER no ambiente}"
: "${DB_PASSWORD:?Defina DB_PASSWORD no ambiente}"
: "${DB_HOST:?Não consegui descobrir DB_HOST automaticamente; defina DB_HOST no ambiente}"

cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: db-conn
  namespace: ${NAMESPACE}
stringData:
  ConnectionStrings__Default: "Host=${DB_HOST};Database=${DB_NAME};Username=${DB_USER};Password=${DB_PASSWORD};Port=5432;SSL Mode=Require;Trust Server Certificate=true"
YAML

echo "Secret 'db-conn' aplicada no namespace ${NAMESPACE}."
