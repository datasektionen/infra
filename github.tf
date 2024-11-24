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

resource "nomad_acl_policy" "deploy_auth" {
  name      = "deploy-auth"
  rules_hcl = <<HCL
    namespace "auth" {
      capabilities = ["read-job", "submit-job"]
    }
  HCL
}

resource "nomad_acl_token" "deploy_auth" {
  name     = "deploy-auth"
  policies = [nomad_acl_policy.deploy_auth.name]
  type     = "client"
}

// Workspace default

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

resource "github_actions_secret" "nomad_token_styrdokument_bawang" {
  repository      = "styrdokument-bawang"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_calypso" {
  repository      = "calypso"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_skywhale" {
  repository      = "skywhale"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_dbuggen" {
  repository      = "dbuggen"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_wookieleaks" {
  repository      = "wookieleaks"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_zfinger" {
  repository      = "zfinger"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_yoggi" {
  repository      = "yoggi"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_aurora" {
  repository      = "aurora"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

resource "github_actions_secret" "nomad_token_ston" {
  repository      = "ston"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_default.secret_id
}

// Workspace auth

resource "github_actions_secret" "nomad_token_dfunkt" {
  repository      = "dfunkt"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_auth.secret_id
}

resource "github_actions_secret" "nomad_token_logout" {
  repository      = "logout"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_auth.secret_id
}

resource "github_actions_secret" "nomad_token_pls" {
  repository      = "pls"
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy_auth.secret_id
}
