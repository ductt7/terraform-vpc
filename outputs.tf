# outputs.tf
output "vpc_cidr" {
  value = aws_vpc.ductt_vpc.cidr_block
}

output "public_subnet_cidrs" {
  value = aws_subnet.public_subnet[*].cidr_block
}

output "private_subnet_cidrs" {
  value = aws_subnet.private_subnet[*].cidr_block
}
