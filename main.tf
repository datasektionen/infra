terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.45.0"
    }
    sshkey = {
      source  = "daveadams/sshkey"
      version = "0.2.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.39.0"
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
  region = "eu-north-1"
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "hcloud_token" {
  sensitive = true
}

variable "ssh_user" {}

resource "sshkey_ed25519_key_pair" "bootstrap" {
  comment = "dsekt-infra-boostrap"
}

resource "hcloud_ssh_key" "bootstrap" {
  name       = "dsekt-infra-bootstrap"
  public_key = sshkey_ed25519_key_pair.bootstrap.public_key
}

resource "hcloud_server" "artemis" {
  name        = "nixos-test"
  image       = "debian-12"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.bootstrap.id]
}

module "artemis_nixos" {
  source                 = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.artemis.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.artemis.config.system.build.diskoScript"

  target_host = hcloud_server.artemis.ipv4_address
  instance_id = hcloud_server.artemis.id

  # this being marked as sensitive hides all output from nixos-anywhere, but that does not print the private key so this is fine
  install_ssh_key = nonsensitive(sshkey_ed25519_key_pair.bootstrap.private_key_pem)
  install_user    = "root"

  target_user = var.ssh_user
}

output "artemis_ipv4" {
  value = hcloud_server.artemis.ipv4_address
}
