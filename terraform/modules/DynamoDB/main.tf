resource "aws_dynamodb_table" "tickets" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ticketId"

  attribute {
    name = "ticketId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Name        = var.table_name
    Environment = var.environment
  })
}

output "table_name" {
  value = aws_dynamodb_table.tickets.name
}

output "table_arn" {
  value = aws_dynamodb_table.tickets.arn
}
