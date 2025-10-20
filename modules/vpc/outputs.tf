output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "private_subnet_a_id" {
  value = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  value = aws_subnet.private_b.id
}

output "private_subnet_c_id" {
  value = aws_subnet.private_c.id
}

output "security_group_id" {
  description = "ID do security group principal"
  value       = aws_security_group.main.id
}