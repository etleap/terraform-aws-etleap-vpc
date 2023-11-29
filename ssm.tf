
resource "aws_ssm_document" "portforward_socks" {
  name          = "PortForwardingSocks-${var.deployment_id}"
  document_type = "Session"

  content = <<DOC
  {
    "schemaVersion": "1.0",
    "description": "Document to start port forwarding session over Session Manager restricted to 1080",
    "sessionType": "Port",
    "parameters": {
      "portNumber": {
        "type": "String",
        "description": "(Optional) Port number of the server on the instance",
        "allowedPattern": "^1080$",
        "default": "1080"
      },
      "localPortNumber": {
        "type": "String",
        "description": "(Optional) Port number on local machine to forward traffic to. An open port is chosen at run-time if not provided",
        "allowedPattern": "^([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$",
        "default": "0"
      }
    },
    "properties": {
      "portNumber": "{{ portNumber }}",
      "type": "LocalPortForwarding",
      "localPortNumber": "{{ localPortNumber }}"
    }
  }
DOC
}

resource "aws_ssm_document" "portforward_db" {
  name          = "PortForwardingDB-${var.deployment_id}"
  document_type = "Session"

  content = <<DOC
  {
    "schemaVersion": "1.0",
    "description": "Document to start port forwarding session to DB over Session Manager restricted to 3306",
    "sessionType": "Port",
    "parameters": {
      "portNumber": {
        "type": "String",
        "description": "(Optional) Port number of the server on the instance",
        "allowedPattern": "^3306$",
        "default": "3306"
      },
      "localPortNumber": {
        "type": "String",
        "description": "(Optional) Port number on local machine to forward traffic to. An open port is chosen at run-time if not provided",
        "allowedPattern": "^([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$",
        "default": "0"
      },
      "host": {
        "type": "String",
        "description": "(Optional) Hostname or IP address of the destination server",
        "allowedPattern": "^[^,$^&\\(\\)!;'\"<>\\`{}\\[\\]\\|#=]{3,}$",
        "default": "localhost"
      }
    },
    "properties": {
      "portNumber": "{{ portNumber }}",
      "type": "LocalPortForwarding",
      "localPortNumber": "{{ localPortNumber }}",
      "host": "{{ host }}"
    }
  }
DOC
}
