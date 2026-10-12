output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the single public subnet."
  value       = module.vpc.public_subnets[0]
}

output "public_route_table_id" {
  description = "Route table associated with the public subnet."
  value       = module.vpc.public_route_table_ids[0]
}

output "internet_gateway_id" {
  description = "ID of the VPC Internet Gateway."
  value       = module.vpc.igw_id
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group that stores VPC Flow Logs."
  value       = module.vpc.vpc_flow_log_destination_arn
}

output "postgres_endpoint" {
  description = "Private PostgreSQL endpoint hostname and port."
  value       = aws_db_instance.postgres.endpoint
}

output "postgres_security_group_id" {
  description = "Security group protecting the PostgreSQL instance."
  value       = aws_security_group.postgres.id
}

output "postgres_master_user_secret_arn" {
  description = "Secrets Manager ARN holding the RDS-generated master password."
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
  sensitive   = true
}

output "ec2_instance_id" {
  description = "ID of the application EC2 instance."
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "Public IP assigned to the EC2 instance. Metabase uses TCP/3000."
  value       = aws_instance.app.public_ip
}

output "metabase_url" {
  description = "Public Metabase URL. Restrict metabase_allowed_cidrs before production use."
  value       = "http://${aws_instance.app.public_dns}:3000"
}

output "ec2_security_group_id" {
  description = "Security group assigned to the EC2 instance."
  value       = aws_security_group.ec2.id
}
