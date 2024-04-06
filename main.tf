terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.39.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.26.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.45.0"
    }
    sshkey = {
      source  = "daveadams/sshkey"
      version = "0.2.1"
    }
  }
  backend "s3" {
    bucket         = "dsekt-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = local.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "cloudflare_api_token" {
  sensitive = true
}

locals {
  aws_region = "eu-north-1"
}

variable "hcloud_token" {
  sensitive = true
}

variable "ssh_user" {}

data "cloudflare_zone" "betasektionen" {
  name = "betasektionen.se"
}

data "cloudflare_zone" "datasektionen" {
  name = "datasektionen.se"
}

resource "sshkey_ed25519_key_pair" "bootstrap" {
  comment = "dsekt-infra-boostrap"
}

resource "hcloud_ssh_key" "bootstrap" {
  name       = "dsekt-infra-bootstrap"
  public_key = sshkey_ed25519_key_pair.bootstrap.public_key
}

resource "hcloud_server" "servers" {
  for_each    = toset(["artemis"])
  name        = each.key
  image       = "debian-12"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.bootstrap.id]
}

resource "hcloud_server" "cluster_servers" {
  for_each    = toset(["zeus", "poseidon", "hades"])
  name        = each.key
  image       = "debian-12"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.bootstrap.id]
}

resource "hcloud_server" "cluster_clients" {
  for_each    = toset(["ares"])
  name        = each.key
  image       = "debian-12"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.bootstrap.id]
}

locals {
  all_hosts = merge(hcloud_server.servers, hcloud_server.cluster_servers, hcloud_server.cluster_clients)
  cluster_roles = {
    for h, _ in local.all_hosts : h =>
    contains(keys(hcloud_server.cluster_servers), h) ? "server"
    : contains(keys(hcloud_server.cluster_clients), h) ? "client"
    : ""
  }
}

module "nixos_install" {
  for_each = local.all_hosts

  source                 = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${each.value.name}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.value.name}.config.system.build.diskoScript"

  target_host = each.value.ipv4_address
  instance_id = each.value.id

  # this being marked as sensitive hides all output from nixos-anywhere, but that does not print the private key so this is fine
  install_ssh_key = nonsensitive(sshkey_ed25519_key_pair.bootstrap.private_key_pem)
  install_user    = "root"

  target_user = var.ssh_user

  extra_files_script = "${path.module}/scripts/get_new_host_files.sh"
  extra_environment = {
    host = each.value.name,
    role = local.cluster_roles[each.value.name],
  }
}

resource "cloudflare_record" "server_name" {
  for_each = local.all_hosts

  name    = each.value.name
  type    = "A"
  zone_id = data.cloudflare_zone.betasektionen.id
  value   = each.value.ipv4_address
}

resource "cloudflare_record" "server_wildcard" {
  for_each = local.all_hosts

  name    = "*.${each.value.name}"
  type    = "A"
  zone_id = data.cloudflare_zone.betasektionen.id
  value   = each.value.ipv4_address
}

resource "aws_ses_domain_identity" "datasektionen" {
  domain = data.cloudflare_zone.datasektionen.name
}

resource "cloudflare_record" "datasektionen_ses_verification" {
  name    = "_amazonses"
  type    = "TXT"
  zone_id = data.cloudflare_zone.datasektionen.id
  value   = aws_ses_domain_identity.datasektionen.verification_token
}

resource "aws_ses_domain_dkim" "datasektionen" {
  domain = data.cloudflare_zone.datasektionen.name
}

resource "cloudflare_record" "datasektionen_ses_dkim" {
  count   = 3
  name    = "${aws_ses_domain_dkim.datasektionen.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  zone_id = data.cloudflare_zone.datasektionen.id
  value   = "${aws_ses_domain_dkim.datasektionen.dkim_tokens[count.index]}.dkim.amazonses.com"
}

resource "aws_ses_domain_mail_from" "datasektionen" {
  domain           = data.cloudflare_zone.datasektionen.name
  mail_from_domain = "sesmail.${data.cloudflare_zone.datasektionen.name}"
}

resource "cloudflare_record" "datasektionen_mail_from_mx" {
  name     = aws_ses_domain_mail_from.datasektionen.mail_from_domain
  type     = "MX"
  zone_id  = data.cloudflare_zone.datasektionen.id
  value    = "feedback-smtp.${local.aws_region}.amazonses.com"
  priority = 10
}

resource "cloudflare_record" "datasektionen_mail_from_spf" {
  name    = aws_ses_domain_mail_from.datasektionen.mail_from_domain
  type    = "TXT"
  zone_id = data.cloudflare_zone.datasektionen.id
  value   = "v=spf1 include:amazonses.com -all"
}
