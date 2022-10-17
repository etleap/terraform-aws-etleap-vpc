output "elva_elb_security_group" {
  value = aws_security_group.elva-elb
}

output "etleap_streaming_ingestion_user" {
  value = aws_iam_user.elva
}