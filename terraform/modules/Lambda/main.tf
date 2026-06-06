# ARCHIVO MODIFICADO
# Lambda/main.tf — agrega variable de entorno AGENTS_TABLE opcional

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/build/${var.function_name}.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}-policy"
  description = "Permisos mínimos para ${var.function_name}."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      },
      {
        Effect = "Allow"
        Action = var.dynamodb_actions
        Resource = concat(
          [var.table_arn, "${var.table_arn}/index/*"],
          var.agents_table_arn != "" ? [var.agents_table_arn, "${var.agents_table_arn}/index/*"] : []
        )
      }
      ],
      var.s3_bucket_arn != "" ? [
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject"
          ]
          Resource = "${var.s3_bucket_arn}/*"
        }
      ] : [],
      var.cognito_user_pool_arn != "" && length(var.cognito_actions) > 0 ? [
        {
          Effect   = "Allow"
          Action   = var.cognito_actions
          Resource = var.cognito_user_pool_arn
        }
    ] : [])
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "function" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = var.handler
  runtime          = var.runtime
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  memory_size      = var.memory_size
  timeout          = var.timeout

  environment {
    variables = merge(
      { TABLE_NAME = var.table_name },
      var.agents_table_name != "" ? { AGENTS_TABLE = var.agents_table_name } : {},
      var.extra_environment_variables
    )
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    aws_cloudwatch_log_group.lambda
  ]

  tags = var.tags
}

output "function_name" {
  value = aws_lambda_function.function.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.function.invoke_arn
}

output "arn" {
  value = aws_lambda_function.function.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.lambda.name
}
