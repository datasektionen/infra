resource "github_actions_organization_variable" "nomad_addr" {
  variable_name = "NOMAD_ADDR"
  value         = "https://nomad.datasektionen.se"
  visibility    = "all"
}

resource "nomad_acl_policy" "deploy_default" {
  name      = "deploy-default"
  rules_hcl = <<HCL
    namespace "default" {
      capabilities = ["read-job", "submit-job"]
    }
  HCL
}

resource "nomad_acl_token" "deploy_default" {
  name     = "deploy-default"
  policies = [nomad_acl_policy.deploy_default.name]
  type     = "client"
}

resource "github_actions_secret" "nomad_token_aaallt2" {
  repository      = "aaallt2"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_taitan" {
  repository      = "taitan"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_bawang" {
  repository      = "bawang"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}
