resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "db_credentials_new_unique"
  description = "Database credentials"

  tags = {
    Name = "db_credentials_new_unique"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "postgres"
    password = var.db_password
  })
}