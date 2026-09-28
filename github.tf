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
      "hive",
      "pls",
      "sso",
    ],
    ddagen = [
      "ddagen",
    ],
    default = [
      "aaallt2",
      "audio",
      "aurora",
      "bawang",
      "bea",
      "chilibea",
      "betting",
      "calypso",
      "damm2",
      "dare",
      "darkmode",
      "dbuggen",
      "djubileet",
      "durn-the-third",
      "femto",
      "foo",
      "harmony",
      "hurryscurry",
      "karon",
      "metasl2",
      "metastudent",
      "meta-tv-rs",
      "methone",
      "nymblan",
      "pandora",
      "pax2",
      "rfinger",
      "skywhale",
      "smingo",
      "spam",
      "spam-rs",
      "ston",
      "styrdokument-bawang",
      "taitan",
      "typst-bot",
      "wookieleaks",
      "yoggi",
      "zaiko",
      "zfinger",
    ],
    dive = [
      "dive-workshop",
    ],
    djulkalendern = [
      "dhost-chat",
      "dhost-commoners",
      "dhost-duckbolt",
      "dhost-sallad",
      "djulkalendern",
      "duckbot",
      "duckbot-jr",
    ],
    jml = [
      "jml",
    ],
    metaspexet = [
      "apollo",
      "haj",
      "metaspexet2",
      "tiki",
    ],
    money = [
      "cashflow",
      "gordian",
    ],
  }

  repo_host_volumes = {
    "apollo" = {
      workspace    = "metaspexet"
      host_volumes = ["apollo"]
    }
  }

  base_repo_to_workspace = { for repo, ws in transpose(local.deploy-tokens) : repo => ws[0] }
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

resource "nomad_acl_policy" "repo_deploy" {
  for_each = local.repo_host_volumes
  name     = "deploy-repo-${each.key}"

  rules_hcl = <<-HCL
    namespace "${each.value.workspace}" {
      capabilities = ["read-job", "submit-job", "parse-job"]
    }

    %{ for vol in each.value.host_volumes ~}
    host_volume "${vol}" {
      capabilities = ["mount-readwrite"]
    }
    %{ endfor ~}
  HCL
}

resource "nomad_acl_token" "deploy" {
  for_each = local.deploy-tokens
  name     = "deploy-${each.key}"
  policies = [nomad_acl_policy.deploy[each.key].name]
  type     = "client"
}

resource "nomad_acl_token" "repo_deploy" {
  for_each = local.repo_host_volumes
  name     = "deploy-repo-${each.key}"
  policies = [nomad_acl_policy.repo_deploy[each.key].name]
  type     = "client"
}

resource "github_actions_secret" "nomad_deploy_token" {
  for_each   = local.base_repo_to_workspace
  repository = each.key
  secret_name = "NOMAD_TOKEN"

  plaintext_value = contains(keys(local.repo_host_volumes), each.key) ? (
    nomad_acl_token.repo_deploy[each.key].secret_id
  ) : (
    nomad_acl_token.deploy[each.value].secret_id
  )
}
