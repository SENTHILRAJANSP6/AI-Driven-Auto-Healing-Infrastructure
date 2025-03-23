output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "sagemaker_endpoint" {
  description = "SageMaker Endpoint"
  value       = aws_sagemaker_model.ai_model.name
}

output "s3_bucket_name" {
  description = "S3 bucket for SageMaker model storage"
  value       = aws_s3_bucket.sagemaker_bucket.bucket
}

output "ecr_repository_url" {
  description = "ECR repository URL for AI model"
  value       = aws_ecr_repository.xgboost_repo.repository_url
}
