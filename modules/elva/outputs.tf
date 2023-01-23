output "elva_lb_public_address" {
  value = aws_lb.elva.dns_name
}

output "elva_lb_private_address_a" {
  value = data.aws_network_interface.lb_subnet_a_ni.private_dns_name
}

output "elva_lb_private_address_b" {
  value = data.aws_network_interface.lb_subnet_b_ni.private_dns_name
}

output "elva_elb_security_group" {
  value = aws_security_group.elva-elb
}

output "etleap_streaming_ingestion_user" {
  value = aws_iam_user.elva
}