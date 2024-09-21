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

# Mattermost

resource "nomad_namespace" "mattermost" {
  name = "mattermost"
}

resource "nomad_job" "mattermost" {
  jobspec = file("${path.module}/jobs/mattermost.nomad.hcl")
}

# Auth

resource "nomad_namespace" "auth" {
  name = "auth"
  description = "Contains jobs that provide auth{entication,orization} for other jobs"
}
