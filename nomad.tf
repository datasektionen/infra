resource "nomad_acl_policy" "read_all_jobs" {
  name = "read-all-jobs"
  description = "Has the `read-job` capability in all namespaces"
  rules_hcl = <<HCL
    namespace "*" {
      capabilities = ["read-job"]
    }
  HCL
}

resource "nomad_acl_token" "traefik" {
  name = "traefik"
  policies = [nomad_acl_policy.read_all_jobs.name]
  type = "client"
  provisioner "local-exec" {
    command = <<BASH
      echo NOMAD_TOKEN=${self.secret_id} | \
        agenix -i $AGE_IDENTITY -e nomad-traefik-acl-token.env.age
    BASH
    working_dir = "./secrets"
  }
}

resource "nomad_job" "keycloak" {
  jobspec = file("${path.module}/keycloak.nomad.hcl")
}
