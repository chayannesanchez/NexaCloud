resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "NexaCloud Betek - API de soporte técnico serverless"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  count         = var.enable_cognito_auth ? 1 : 0
  name          = "nexacloud-cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_resource" "tickets" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "tickets"
}

resource "aws_api_gateway_resource" "tickets_create" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.tickets.id
  path_part   = "create"
}

resource "aws_api_gateway_resource" "tickets_list" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.tickets.id
  path_part   = "list"
}

resource "aws_api_gateway_resource" "tickets_track" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.tickets.id
  path_part   = "track"
}

resource "aws_api_gateway_resource" "tickets_track_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.tickets_track.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "tickets_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.tickets.id
  path_part   = "{id}"
}

resource "aws_api_gateway_resource" "tickets_id_update" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.tickets_id.id
  path_part   = "update"
}

locals {
  cors_headers = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  cors_response_headers_base = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_method" "tickets_create_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_create.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tickets_create_post" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.tickets_create.id
  http_method             = aws_api_gateway_method.tickets_create_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_tickets_create_invoke_arn
}

resource "aws_api_gateway_method" "tickets_list_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_list.id
  http_method   = "GET"
  authorization = var.enable_cognito_auth ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.enable_cognito_auth ? aws_api_gateway_authorizer.cognito[0].id : null
}

resource "aws_api_gateway_integration" "tickets_list_get" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.tickets_list.id
  http_method             = aws_api_gateway_method.tickets_list_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_tickets_get_invoke_arn
}

resource "aws_api_gateway_method" "tickets_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_id.id
  http_method   = "GET"
  authorization = var.enable_cognito_auth ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.enable_cognito_auth ? aws_api_gateway_authorizer.cognito[0].id : null
}

resource "aws_api_gateway_integration" "tickets_id_get" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.tickets_id.id
  http_method             = aws_api_gateway_method.tickets_id_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_tickets_get_invoke_arn
}

resource "aws_api_gateway_method" "tickets_track_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_track_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tickets_track_get" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.tickets_track_id.id
  http_method             = aws_api_gateway_method.tickets_track_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_tickets_get_invoke_arn
}

resource "aws_api_gateway_method" "tickets_update_put" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_id_update.id
  http_method   = "PUT"
  authorization = var.enable_cognito_auth ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.enable_cognito_auth ? aws_api_gateway_authorizer.cognito[0].id : null
}

resource "aws_api_gateway_integration" "tickets_update_put" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.tickets_id_update.id
  http_method             = aws_api_gateway_method.tickets_update_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_tickets_update_invoke_arn
}

resource "aws_api_gateway_method" "tickets_create_options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_create.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tickets_create_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_create.id
  http_method = aws_api_gateway_method.tickets_create_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "tickets_create_options" {
  rest_api_id         = aws_api_gateway_rest_api.api.id
  resource_id         = aws_api_gateway_resource.tickets_create.id
  http_method         = aws_api_gateway_method.tickets_create_options.http_method
  status_code         = "200"
  response_parameters = local.cors_headers
}

resource "aws_api_gateway_integration_response" "tickets_create_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_create.id
  http_method = aws_api_gateway_method.tickets_create_options.http_method
  status_code = aws_api_gateway_method_response.tickets_create_options.status_code

  response_parameters = merge(local.cors_response_headers_base, {
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  })

  depends_on = [aws_api_gateway_integration.tickets_create_options]
}

resource "aws_api_gateway_method" "tickets_list_options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_list.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tickets_list_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_list.id
  http_method = aws_api_gateway_method.tickets_list_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "tickets_list_options" {
  rest_api_id         = aws_api_gateway_rest_api.api.id
  resource_id         = aws_api_gateway_resource.tickets_list.id
  http_method         = aws_api_gateway_method.tickets_list_options.http_method
  status_code         = "200"
  response_parameters = local.cors_headers
}

resource "aws_api_gateway_integration_response" "tickets_list_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_list.id
  http_method = aws_api_gateway_method.tickets_list_options.http_method
  status_code = aws_api_gateway_method_response.tickets_list_options.status_code

  response_parameters = merge(local.cors_response_headers_base, {
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
  })

  depends_on = [aws_api_gateway_integration.tickets_list_options]
}

resource "aws_api_gateway_method" "tickets_id_options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tickets_id_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_id.id
  http_method = aws_api_gateway_method.tickets_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "tickets_id_options" {
  rest_api_id         = aws_api_gateway_rest_api.api.id
  resource_id         = aws_api_gateway_resource.tickets_id.id
  http_method         = aws_api_gateway_method.tickets_id_options.http_method
  status_code         = "200"
  response_parameters = local.cors_headers
}

resource "aws_api_gateway_integration_response" "tickets_id_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_id.id
  http_method = aws_api_gateway_method.tickets_id_options.http_method
  status_code = aws_api_gateway_method_response.tickets_id_options.status_code

  response_parameters = merge(local.cors_response_headers_base, {
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
  })

  depends_on = [aws_api_gateway_integration.tickets_id_options]
}

resource "aws_api_gateway_method" "tickets_track_options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_track_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tickets_track_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_track_id.id
  http_method = aws_api_gateway_method.tickets_track_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "tickets_track_options" {
  rest_api_id         = aws_api_gateway_rest_api.api.id
  resource_id         = aws_api_gateway_resource.tickets_track_id.id
  http_method         = aws_api_gateway_method.tickets_track_options.http_method
  status_code         = "200"
  response_parameters = local.cors_headers
}

resource "aws_api_gateway_integration_response" "tickets_track_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_track_id.id
  http_method = aws_api_gateway_method.tickets_track_options.http_method
  status_code = aws_api_gateway_method_response.tickets_track_options.status_code

  response_parameters = merge(local.cors_response_headers_base, {
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
  })

  depends_on = [aws_api_gateway_integration.tickets_track_options]
}

resource "aws_api_gateway_method" "tickets_update_options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.tickets_id_update.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tickets_update_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_id_update.id
  http_method = aws_api_gateway_method.tickets_update_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "tickets_update_options" {
  rest_api_id         = aws_api_gateway_rest_api.api.id
  resource_id         = aws_api_gateway_resource.tickets_id_update.id
  http_method         = aws_api_gateway_method.tickets_update_options.http_method
  status_code         = "200"
  response_parameters = local.cors_headers
}

resource "aws_api_gateway_integration_response" "tickets_update_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.tickets_id_update.id
  http_method = aws_api_gateway_method.tickets_update_options.http_method
  status_code = aws_api_gateway_method_response.tickets_update_options.status_code

  response_parameters = merge(local.cors_response_headers_base, {
    "method.response.header.Access-Control-Allow-Methods" = "'PUT,OPTIONS'"
  })

  depends_on = [aws_api_gateway_integration.tickets_update_options]
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.tickets.id,
      aws_api_gateway_resource.tickets_create.id,
      aws_api_gateway_resource.tickets_list.id,
      aws_api_gateway_resource.tickets_track.id,
      aws_api_gateway_resource.tickets_track_id.id,
      aws_api_gateway_resource.tickets_id.id,
      aws_api_gateway_resource.tickets_id_update.id,
      aws_api_gateway_method.tickets_create_post.id,
      aws_api_gateway_method.tickets_list_get.id,
      aws_api_gateway_method.tickets_id_get.id,
      aws_api_gateway_method.tickets_track_get.id,
      aws_api_gateway_method.tickets_update_put.id,
      aws_api_gateway_integration.tickets_create_post.id,
      aws_api_gateway_integration.tickets_list_get.id,
      aws_api_gateway_integration.tickets_id_get.id,
      aws_api_gateway_integration.tickets_track_get.id,
      aws_api_gateway_integration.tickets_update_put.id,
      aws_api_gateway_integration_response.tickets_create_options.id,
      aws_api_gateway_integration_response.tickets_list_options.id,
      aws_api_gateway_integration_response.tickets_id_options.id,
      aws_api_gateway_integration_response.tickets_track_options.id,
      aws_api_gateway_integration_response.tickets_update_options.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.tickets_create_post,
    aws_api_gateway_integration.tickets_list_get,
    aws_api_gateway_integration.tickets_id_get,
    aws_api_gateway_integration.tickets_track_get,
    aws_api_gateway_integration.tickets_update_put,
    aws_api_gateway_integration_response.tickets_create_options,
    aws_api_gateway_integration_response.tickets_list_options,
    aws_api_gateway_integration_response.tickets_id_options,
    aws_api_gateway_integration_response.tickets_track_options,
    aws_api_gateway_integration_response.tickets_update_options,
  ]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.stage_name
}

resource "aws_lambda_permission" "tickets_create" {
  statement_id  = "AllowAPIGatewayInvokeTicketsCreate"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_tickets_create_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "tickets_get" {
  statement_id  = "AllowAPIGatewayInvokeTicketsGet"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_tickets_get_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "tickets_update" {
  statement_id  = "AllowAPIGatewayInvokeTicketsUpdate"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_tickets_update_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

output "api_endpoint" {
  value       = aws_api_gateway_stage.prod.invoke_url
  description = "URL base del REST API Gateway."
}
