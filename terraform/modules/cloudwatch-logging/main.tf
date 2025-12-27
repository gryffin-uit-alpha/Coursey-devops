
# Namespace

resource "kubernetes_namespace" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
}

# S3 Bucket for Log Archival

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.cluster_name}-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name    = "${var.cluster_name}-logs"
    Purpose = "EKS Log Archival"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-retention"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    # Expiration days must be greater than transition days
    expiration {
      days = var.log_retention_days + 30
    }

    transition {
      days          = var.log_retention_days
      storage_class = "GLACIER"
    }
  }
}

# CloudWatch Log Groups


resource "aws_cloudwatch_log_group" "eks_application" {
  name              = "/aws/eks/${var.cluster_name}/application"
  retention_in_days = var.log_retention_days

  tags = {
    Cluster = var.cluster_name
    Type    = "application"
  }
}

resource "aws_cloudwatch_log_group" "eks_dataplane" {
  name              = "/aws/eks/${var.cluster_name}/dataplane"
  retention_in_days = var.log_retention_days

  tags = {
    Cluster = var.cluster_name
    Type    = "dataplane"
  }
}

# Fluent Bit IAM Role (IRSA)

resource "aws_iam_policy" "fluent_bit_policy" {
  name        = "FluentBitPolicy-${var.cluster_name}"
  description = "Allow Fluent Bit to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

module "fluent_bit_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "fluent-bit-role-${var.cluster_name}"

  role_policy_arns = {
    fluent_bit = aws_iam_policy.fluent_bit_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["amazon-cloudwatch:fluent-bit"]
    }
  }
}

# Fluent Bit Helm Release

resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  namespace  = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  version    = "0.1.32"

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "fluent-bit"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.fluent_bit_role.iam_role_arn
  }

  set {
    name  = "cloudWatchLogs.enabled"
    value = "true"
  }

  set {
    name  = "cloudWatchLogs.region"
    value = var.region
  }

  set {
    name  = "cloudWatchLogs.logGroupName"
    value = aws_cloudwatch_log_group.eks_application.name
  }

  set {
    name  = "cloudWatchLogs.autoCreateGroup"
    value = "false"
  }

  set {
    name  = "firehose.enabled"
    value = "false"
  }

  set {
    name  = "kinesis.enabled"
    value = "false"
  }

  set {
    name  = "elasticsearch.enabled"
    value = "false"
  }

  depends_on = [aws_cloudwatch_log_group.eks_application]
}

# Kinesis Firehose for S3 Export

resource "aws_iam_role" "firehose_role" {
  name = "firehose-logs-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_s3_policy" {
  name = "firehose-s3-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "logs_to_s3" {
  name        = "${var.cluster_name}-logs-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_role.arn
    bucket_arn          = aws_s3_bucket.logs.arn
    prefix              = "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"

    buffering_size     = 5
    buffering_interval = 300

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.eks_dataplane.name
      log_stream_name = "S3Delivery"
    }
  }
}

# CloudWatch to Firehose Subscription


resource "aws_iam_role" "cloudwatch_to_firehose" {
  name = "cloudwatch-to-firehose-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_to_firehose_policy" {
  name = "cloudwatch-to-firehose-policy"
  role = aws_iam_role.cloudwatch_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = aws_kinesis_firehose_delivery_stream.logs_to_s3.arn
      }
    ]
  })
}

resource "aws_cloudwatch_log_subscription_filter" "logs_to_firehose" {
  name            = "logs-to-s3-${var.cluster_name}"
  log_group_name  = aws_cloudwatch_log_group.eks_application.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.logs_to_s3.arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose.arn

  depends_on = [aws_iam_role_policy.cloudwatch_to_firehose_policy]
}
