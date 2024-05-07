resource "aws_dynamodb_table" "activity-log" {
  tags          = local.default_tags
  name          = "EtleapActivityLog-${var.deployment_id}"
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "ProjectActivityTypeIsError"
  range_key     = "LogTimestamp"

  attribute {
    name = "ProjectActivityTypeIsError"
    type = "S"
  }

  attribute {
    name = "LogTimestamp"
    type = "S"
  }

  attribute {
    name = "BatchUuidTimestamp"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  local_secondary_index {
    name = "BatchUuidTimestampIndex"
    range_key = "BatchUuidTimestamp"
    projection_type = "KEYS_ONLY"
  }

  deletion_protection_enabled = true
}