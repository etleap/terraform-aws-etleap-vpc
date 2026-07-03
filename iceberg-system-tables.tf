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

// When the Glue Data Catalog is in Lake Formation enforced mode, the app/EMR roles need explicit
// LF grants on the system tables (the IAM policy above only covers default IAM access control).
// Detected automatically: enforced mode removes ALL/IAM_ALLOWED_PRINCIPALS from the account's
// create_table_default_permissions, which newly created tables would otherwise inherit. When
// enforced, the deploying principal must be an LF data-lake administrator.
data "aws_lakeformation_data_lake_settings" "current" {
  catalog_id = local.account_id
}

locals {
  lake_formation_enforced = !contains([
    for p in data.aws_lakeformation_data_lake_settings.current.create_table_default_permissions : p.principal
    if contains(p.permissions, "ALL")
  ], "IAM_ALLOWED_PRINCIPALS")
}

// App creates the system tables (CREATE_TABLE on the DB) and manages them (table DESCRIBE/ALTER/DROP).
resource "aws_lakeformation_permissions" "iceberg_system_tables_app_database" {
  count       = local.lake_formation_enforced ? 1 : 0
  principal   = aws_iam_role.app.arn
  permissions = ["CREATE_TABLE"]

  database {
    name       = aws_glue_catalog_database.iceberg_system_tables_db.name
    catalog_id = local.account_id
  }
}

resource "aws_lakeformation_permissions" "iceberg_system_tables_app_tables" {
  count       = local.lake_formation_enforced ? 1 : 0
  principal   = aws_iam_role.app.arn
  permissions = ["DESCRIBE", "ALTER", "DROP"]

  table {
    database_name = aws_glue_catalog_database.iceberg_system_tables_db.name
    catalog_id    = local.account_id
    wildcard      = true
  }
}

// EMR reads and commits to the app-created system tables during ingest.
resource "aws_lakeformation_permissions" "iceberg_system_tables_emr_tables" {
  count       = local.lake_formation_enforced ? 1 : 0
  principal   = aws_iam_role.emr.arn
  permissions = ["DESCRIBE", "ALTER"]

  table {
    database_name = aws_glue_catalog_database.iceberg_system_tables_db.name
    catalog_id    = local.account_id
    wildcard      = true
  }
}
