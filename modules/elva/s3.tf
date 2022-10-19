// Default object required for successful Elva initialisation
resource "aws_s3_bucket_object" "default_config" {
    bucket  = var.config_bucket.bucket
    key     = "streaming-configuration/00000.yaml"
    content = <<EOF
webhooks:
  /test/: "test"

buckets:
  test:
    bucket: test-streaming-ingress
    aws_key_id: placeholder-aws-id
    aws_sec_key: placeholder-aws-security-key
  default:
    bucket: streaming-ingress
    aws_key_id: placeholder-aws-id
    aws_sec_key: placeholder-aws-security-key
EOF
}