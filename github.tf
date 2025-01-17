resource "github_actions_organization_variable" "nomad_addr" {
  variable_name = "NOMAD_ADDR"
  value         = "https://nomad.datasektionen.se"
  visibility    = "all"
}

locals {
  # Workspace to list of repos that deploy to the workspace. The workspace must already exist.
  deploy-tokens = {
    auth = [
      "dfunkt",
      "sso",
      "pls",
    ],
    default = [
      "aaallt2",
      "taitan",
      "bawang",
      "styrdokument_bawang",
      "calypso",
      "skywhale",
      "dbuggen",
      "wookieleaks",
      "zfinger",
      "yoggi",
      "aurora",
      "ston",
      "methone",
      "smingo",
    ],
  }
}

resource "nomad_acl_policy" "deploy" {
  for_each  = local.deploy-tokens
  name      = "deploy-${each.key}"
  rules_hcl = <<HCL
    namespace "${each.key}" {
      capabilities = ["read-job", "submit-job"]
    }
  HCL
}

resource "nomad_acl_token" "deploy" {
  for_each = local.deploy-tokens
  name     = "deploy-${each.key}"
  policies = [nomad_acl_policy.deploy[each.key].name]
  type     = "client"
}

resource "github_actions_secret" "nomad_deploy_token" {
  for_each        = { for repo, ws in transpose(local.deploy-tokens) : repo => ws[0] }
  repository      = each.key
  secret_name     = "NOMAD_TOKEN"
  plaintext_value = nomad_acl_token.deploy[each.value].secret_id
}
