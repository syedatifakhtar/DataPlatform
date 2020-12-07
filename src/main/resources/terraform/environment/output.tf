output "vpc_id" {
  value = aws_vpc.main.id
}

output "security_group_id" {
  value = aws_security_group.allow_access.id
}

output "subnet_public_1_id" {
  value = aws_subnet.public_1.id
}

output "subnet_public_2_id" {
  value = aws_subnet.public_2.id
}

output "subnet_private_1_id" {
  value = aws_subnet.private_1.id
}

output "subnet_private_2_id" {
  value = aws_subnet.private_2.id
}