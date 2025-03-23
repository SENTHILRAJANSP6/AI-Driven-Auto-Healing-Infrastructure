# ------------------------------------------
# IAM Role for EC2 (CloudWatch Auto-Healing)
# ------------------------------------------
resource "aws_iam_role" "cloudwatch_role" {
  name = "CloudWatchRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "cloudwatch_profile" {
  name = "CloudWatchInstanceProfile"
  role = aws_iam_role.cloudwatch_role.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ------------------------------------------
# EC2 Instance (Auto-Healing)
# ------------------------------------------
resource "aws_instance" "web" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.cloudwatch_profile.name

  tags = {
    Name = "Auto_Healing_Instance"
  }
}

# ------------------------------------------
# CloudWatch Alarm for Auto Healing
# ------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "CPU_Usage_Too_Low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm when CPU utilization falls below 1%"
  alarm_actions       = ["arn:aws:automate:${var.aws_region}:ec2:recover"]

  dimensions = {
    InstanceId = aws_instance.web.id
  }
}

# ------------------------------------------
# SageMaker IAM Role & Model Deployment
# ------------------------------------------
resource "aws_iam_role" "sagemaker_role" {
  name = "SagemakerExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_s3_policy" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  depends_on = [aws_iam_role.sagemaker_role]
}

resource "aws_sagemaker_model" "ai_model" {
  name              = "AutoHealingModel"
  execution_role_arn = aws_iam_role.sagemaker_role.arn

  primary_container {
    image = "811284229777.dkr.ecr.${var.aws_region}.amazonaws.com/xgboost:latest"
    model_data_url = "s3://${aws_s3_bucket.sagemaker_bucket.id}/model.tar.gz"
  }
}

# ------------------------------------------
# S3 Bucket for SageMaker (Auto-Healing Model Storage)
# ------------------------------------------
resource "aws_s3_bucket" "sagemaker_bucket" {
  bucket = "ai-auto-healing-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# ------------------------------------------
# ECR Repository for SageMaker
# ------------------------------------------
resource "aws_ecr_repository" "xgboost_repo" {
  name = var.ecr_repository_name
}

resource "aws_ecr_repository_policy" "sagemaker_ecr_policy" {
  repository = aws_ecr_repository.xgboost_repo.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "sagemaker.amazonaws.com" },
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }]
  })
}
resource "aws_iam_role_policy" "sagemaker_s3_access" {
  name   = "SagemakerS3AccessPolicy"
  role   = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.sagemaker_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.sagemaker_bucket.id}/*"
        ]
      }
    ]
  })
}
