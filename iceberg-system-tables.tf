resource "aws_glue_catalog_database" "iceberg_system_tables_db" {
  # Sanitizing the name as Iceberg does not allow for table names to contain hyphens or upper-case characters
  name        = format("etleap_%s_iceberg_system_tables", replace(lower(var.deployment_id), "-", "_"))
  description = "Glue database to catalog iceberg system tables required for certain pipeline operations, such as schema change tracking and parsing error detection, for Iceberg pipelines"
}

// The permissions required to interact with the tables in the iceberg_system_tables_db catalog
resource "aws_iam_policy" "iceberg_system_tables_access" {
  name   = "Etleap-${var.deployment_id}-App-IcebergSystemTable-Limited-Policy"
  description = "The permissions required to interact with the tables in the ${aws_glue_catalog_database.iceberg_system_tables_db.name} catalog"
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:DeleteTable"
        ],
        "Resource": [
          "arn:aws:glue:${local.region}:${local.account_id}:catalog",
          "${aws_glue_catalog_database.iceberg_system_tables_db.arn}",
          "arn:aws:glue:${local.region}:${local.account_id}:table/${aws_glue_catalog_database.iceberg_system_tables_db.name}/*"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_policy_attachment" "iceberg_system_tables_access_attachment" {
  name       = aws_iam_policy.iceberg_system_tables_access.name
  roles      = [aws_iam_role.app.name, aws_iam_role.emr.name]
  policy_arn = aws_iam_policy.iceberg_system_tables_access.arn
}