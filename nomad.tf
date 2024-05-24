resource "nomad_acl_policy" "read_all_jobs" {
  name        = "read-all-jobs"
  description = "Has the `read-job` capability in all namespaces"
  rules_hcl   = <<HCL
    namespace "*" {
      capabilities = ["read-job"]
    }
  HCL
}

resource "nomad_acl_token" "traefik" {
  name     = "traefik"
  policies = [nomad_acl_policy.read_all_jobs.name]
  type     = "client"
  provisioner "local-exec" {
    command     = <<BASH
      rm nomad-traefik-acl-token.env.age
      echo NOMAD_TOKEN=${self.secret_id} | \
        agenix -e nomad-traefik-acl-token.env.age
    BASH
    working_dir = "./secrets"
  }
}

# resource "nomad_variable" "jobs_mattermost" {
#   path = "nomad/jobs/mattermost"
#   items = {
#     smtp_username = aws_iam_access_key.mattermost_smtp.id
#     smtp_password = aws_iam_access_key.mattermost_smtp.ses_smtp_password_v4
#   }
# }

# resource "nomad_job" "keycloak" {
#   jobspec = file("${path.module}/keycloak.nomad.hcl")
# }

resource "nomad_namespace" "mattermost" {
  name = "mattermost"
}

resource "nomad_job" "mattermost" {
  jobspec = file("${path.module}/mattermost.nomad.hcl")
}
