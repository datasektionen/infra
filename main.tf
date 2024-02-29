terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.45.0"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

variable "ssh_user" {}

resource "hcloud_ssh_key" "mathm5nfc" {
  name       = "mathmyubikey5nfc"
  public_key = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEdUe7mxGdV/Q37RKndPzDHisFb7q/xm+L97jcGluSDOA8MGt/+wTxpyGxfyEqaMvwV2bakaMVHTB3711dDu5kE= m5nfc"
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_server" "artemis" {
  name        = "nixos-test"
  image       = "debian-12"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.mathm5nfc.id]
}

module "deploy" {
  source                 = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.artemis.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.artemis.config.system.build.diskoScript"

  target_host = hcloud_server.artemis.ipv4_address
  instance_id = hcloud_server.artemis.id

  install_user = "root"
  target_user  = var.ssh_user
}

output "artemis_ipv4" {
  value = hcloud_server.artemis.ipv4_address
}
