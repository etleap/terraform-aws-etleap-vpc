variable deployment_random {
}

variable resource_name_suffix {
}

variable app_role_name {
}

variable vpc_id {
}

variable key_name {   
}

variable subnet_a_public_id {
}

variable subnet_a_private_id {
}

variable subnet_b_public_id {
}

variable subnet_b_private_id {
}

variable region {
}

variable config_bucket {
}

variable "non_critical_cloudwatch_alarm_sns_topics" {
}

variable "critical_cloudwatch_alarm_sns_topics" {
}

variable "deployment_id" {
}

variable "acm_certificate_arn" {
}

variable "streaming_endpoint_access_cidr_blocks" {
}

variable "app_security_group_id" {
}

variable "tags" {
  type = map(string)
  default = {}
}