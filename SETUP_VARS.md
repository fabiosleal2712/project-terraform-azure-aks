# Configuração das Variáveis OpenTofu

## Pré-requisitos

### 1. Configure o AWS CLI
```bash
aws configure
```

Ou configure as variáveis de ambiente:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Obter AMI ID atualizada
Para obter a AMI mais recente do Amazon Linux 2:
```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text \
  --region us-east-1
```

### 3. Criar IAM Role para EKS
Você precisa criar uma IAM role para o cluster EKS:

1. Vá para o console AWS IAM
2. Crie uma nova role com o tipo "AWS Service" → "EKS - Cluster"
3. Anexe as políticas necessárias:
   - AmazonEKSClusterPolicy
4. Anote o ARN da role criada

### 4. Configurar terraform.tfvars
```bash
cp terraform.tfvars.example terraform.tfvars
# Edite o arquivo com seus valores reais
```

## Valores necessários no terraform.tfvars:

```hcl
# Se não usar AWS CLI, descomente e preencha:
# aws_access_key = "AKIA..."
# aws_secret_key = "..."

ami_id = "ami-0c02fb55956c7d316"  # Ubuntu 20.04 LTS
instance_type = "t2.micro"
subnet_ids = []
provider_path = "/usr/bin/tofu"
cluster_role_arn = "arn:aws:iam::SEU_ACCOUNT_ID:role/eks-cluster-service-role"
cluster_name = "my-eks-cluster"
principal_arn = "arn:aws:iam::SEU_ACCOUNT_ID:root"
```

## Executar o OpenTofu

```bash
# Inicializar (já feito)
tofu init

# Planejar
tofu plan

# Aplicar
tofu apply
```

## Limpeza
```bash
tofu destroy
```