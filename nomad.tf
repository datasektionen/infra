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

# Vault

variable "vault_db_password" {
  sensitive = true
}

resource "nomad_namespace" "vault" {
  name = "vault"
}

resource "nomad_job" "vault" {
  jobspec = file("${path.module}/jobs/vaultwarden.nomad.hcl")
}

resource "nomad_variable" "jobs_vault" {
  path      = "nomad/jobs/vault"
  namespace = "vault"
  items = {
    db_password   = var.vault_db_password
    smtp_username = aws_iam_access_key.vaultwarden_smtp.id
    smtp_password = aws_iam_access_key.vaultwarden_smtp.ses_smtp_password_v4
  }
}

# Twenty

resource "nomad_namespace" "twenty" {
  name = "twenty"
}

resource "nomad_job" "twenty" {
  jobspec = file("${path.module}/jobs/twenty.nomad.hcl")
}

# Auth

resource "nomad_namespace" "auth" {
  name        = "auth"
  description = "Contains jobs that provide auth{entication,orization} for other jobs"
}

# D-Dagen

resource "nomad_namespace" "ddagen" {
  name        = "ddagen"
  description = "Contains jobs for D-Dagen's production and preview environments"
}

# Other Third-Party Jobs in Default

resource "nomad_job" "djul-redirect" {
  jobspec = file("${path.module}/jobs/djul-redirect.nomad.hcl")
}

resource "nomad_job" "planka" {
  jobspec = file("${path.module}/jobs/planka.nomad.hcl")
}

# Policies for humans

locals {
  namespaces_for_humans = toset(["default", "auth", "ddagen"])
}

resource "nomad_acl_policy" "manage_jobs" {
  for_each    = local.namespaces_for_humans
  name        = "manage-jobs-in-${each.value}"
  description = "Can manage jobs in the ${each.value} namespace"
  rules_hcl   = <<HCL
    namespace "${each.value}" {
      variables {
        # These can be read anyway by execing into a job and echoing env variables,
        # though perhaps write access could be more restricted.
        path "nomad/jobs/*" {
          capabilities = ["read", "write"]
        }
      }
      policy = "write"
    }
  HCL
}
