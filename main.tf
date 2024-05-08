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
    nomad = {
      source = "hashicorp/nomad"
      version = "2.2.0"
    }
    sshkey = {
      source  = "daveadams/sshkey"
      version = "0.2.1"
    }
    random = {
      source = "hashicorp/random"
      version = "3.6.1"
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

resource "hcloud_network" "cluster" {
  name     = "nomad-cluster-network"
  ip_range = "10.83.0.0/16"
}

resource "hcloud_network_subnet" "cluster-main" {
  network_id   = hcloud_network.cluster.id
  type         = "cloud"
  ip_range     = "10.83.0.0/16"
  network_zone = "eu-central"
}

resource "cloudflare_record" "zone_wildcard" {
  name    = "*"
  type    = "A"
  zone_id = data.cloudflare_zone.betasektionen.id
  value   = hcloud_server.cluster_hosts["ares"].ipv4_address
}
