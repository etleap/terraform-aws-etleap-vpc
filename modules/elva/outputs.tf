output "elva_lb_public_address" {
  value = aws_lb.elva.dns_name
}

output "elva_elb_security_group" {
  value = aws_security_group.elva-elb
}

output "etleap_streaming_ingestion_user" {
  value = aws_iam_user.elva
}