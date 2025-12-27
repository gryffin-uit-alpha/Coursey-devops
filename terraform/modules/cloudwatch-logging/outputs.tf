output "cloudwatch_log_group_application" {
  description = "CloudWatch Log Group for application logs"
  value       = aws_cloudwatch_log_group.eks_application.name
}

output "cloudwatch_log_group_dataplane" {
  description = "CloudWatch Log Group for dataplane logs"
  value       = aws_cloudwatch_log_group.eks_dataplane.name
}

output "s3_bucket_name" {
  description = "S3 bucket for archived logs"
  value       = aws_s3_bucket.logs.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for archived logs"
  value       = aws_s3_bucket.logs.arn
}

output "fluent_bit_role_arn" {
  description = "IAM role ARN for Fluent Bit"
  value       = module.fluent_bit_role.iam_role_arn
}
