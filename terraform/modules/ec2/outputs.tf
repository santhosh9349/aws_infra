output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "The private IP of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "The public IP of the EC2 instance (null for instances in private subnets)"
  value       = aws_instance.this.public_ip
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.web_server.id
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.ssm_role.arn
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = aws_iam_instance_profile.ssm_instance.name
}
