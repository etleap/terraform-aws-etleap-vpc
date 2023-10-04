
resource "aws_ssm_document" "portforward_socks" {
  count         = var.disable_ssm_access ? 0 : 1
  name          = "PortForwardingSocks"
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
