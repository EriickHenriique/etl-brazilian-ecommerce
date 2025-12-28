variable "target_bucket" {
  type = string
}

# Zip do código da Lambda 
data "archive_file" "extract_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/extract"
  output_path = "${path.module}/build/extract.zip"
}

# IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "extract-insert-files-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Policy S3
resource "aws_iam_policy" "lambda_s3_policy" {
  name = "extract-insert-files-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:PutObject"]
      Resource = "arn:aws:s3:::${var.target_bucket}/*"
    }]
  })
}

# Attach policies
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "logs_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda
resource "aws_lambda_function" "extract" {
  function_name = "extract-insert-files"
  role          = aws_iam_role.lambda_role.arn
  handler       = "insert_files.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.extract_lambda_zip.output_path
  source_code_hash = data.archive_file.extract_lambda_zip.output_base64sha256

  timeout     = 30
  memory_size = 256

  environment {
    variables = {
      TARGET_BUCKET = var.target_bucket
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.s3_attach,
    aws_iam_role_policy_attachment.logs_attach
  ]
}
