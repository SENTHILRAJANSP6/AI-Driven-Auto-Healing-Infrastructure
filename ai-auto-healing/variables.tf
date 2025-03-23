variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Amazon Machine Image ID"
  type        = string
  default     = "ami-08b5b3a93ed654d19"
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR repository name for AI model"
  type        = string
  default     = "xgboost"
}
