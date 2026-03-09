# CodeConnections host
# Created only for self-managed providers
resource "aws_codestarconnections_host" "source_host" {
  count = (
  var.create_codestar_host &&
  contains(["GitLabSelfManaged", "GitHubEnterpriseServer"], var.codestar_provider_type)
  ) ? 1 : 0

  name              = var.codestar_host_name
  provider_type     = var.codestar_provider_type
  provider_endpoint = var.codestar_provider_endpoint
}

# CodeConnections connection
resource "aws_codestarconnections_connection" "source_connection" {
  count = var.create_codestar_connection ? 1 : 0

  name = var.codestar_connection_name

  host_arn = contains(
    ["GitLabSelfManaged", "GitHubEnterpriseServer"],
    var.codestar_provider_type
  ) ? aws_codestarconnections_host.source_host[0].arn : null

  provider_type = contains(
    ["GitLabSelfManaged", "GitHubEnterpriseServer"],
    var.codestar_provider_type
  ) ? null : var.codestar_provider_type
}