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
    github = {
      source  = "integrations/github"
      version = "6.2.1"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.49.1"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
  backend "s3" {
    bucket         = "dsekt-tf-state"
    key            = "terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "tf-lock"
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

provider "github" {
  owner = "datasektionen"
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

variable "domainname" {
  default = "datasektionen.se"
}

data "cloudflare_zone" "main" {
  name = "${var.domainname}"
}

resource "cloudflare_record" "zone_apex" {
  name    = "@"
  type    = "A"
  zone_id = data.cloudflare_zone.main.id
  value   = hcloud_server.cluster_hosts["ares"].ipv4_address
}

resource "cloudflare_record" "zone_wildcard" {
  name    = "*"
  type    = "A"
  zone_id = data.cloudflare_zone.main.id
  value   = hcloud_server.cluster_hosts["ares"].ipv4_address
}

data "cloudflare_api_token_permission_groups" "all" {}
resource "cloudflare_api_token" "acme_dns_challenge" {
  name = "tf-acme-dns-challenge"
  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.*" = "*"
    }
  }
  provisioner "local-exec" {
    command     = <<BASH
      rm cloudflare-dns-api-token.env.age
      echo "CLOUDFLARE_DNS_API_TOKEN=${self.value}" | \
        agenix -e cloudflare-dns-api-token.env.age
    BASH
    working_dir = "./secrets"
  }
}

resource "local_file" "tofu_nix" {
  filename = "${path.module}/tofu.nix"
  content = <<NIX
{
  domainname = "${var.domainname}";
}
NIX
}
