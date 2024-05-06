locals {
  # NOTE: Must be kept in sync with `config.dsekt.addresses.hosts` in nix
  cluster_hosts = {
    zeus     = { role = "server", private_ip_addr = "10.83.0.2" },
    poseidon = { role = "server", private_ip_addr = "10.83.0.3" },
    hades    = { role = "server", private_ip_addr = "10.83.0.4" },
    ares     = { role = "client", private_ip_addr = "10.83.0.5" },
  }
}

resource "hcloud_server" "cluster_hosts" {
  for_each    = local.cluster_hosts
  name        = each.key
  image       = "debian-12"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.bootstrap.id]
  network {
    network_id = hcloud_network.cluster.id
    ip         = each.value.private_ip_addr
  }
  depends_on = [hcloud_network_subnet.cluster-main]
}

module "nixos_install" {
  for_each = local.cluster_hosts

  source                 = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${each.key}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.key}.config.system.build.diskoScript"

  target_host = hcloud_server.cluster_hosts[each.key].ipv4_address
  instance_id = hcloud_server.cluster_hosts[each.key].id

  # this being marked as sensitive hides all output from nixos-anywhere, but that does not print the private key so this is fine
  install_ssh_key = nonsensitive(sshkey_ed25519_key_pair.bootstrap.private_key_pem)
  install_user    = "root"

  target_user = var.ssh_user

  extra_files_script = "${path.module}/scripts/get_new_host_files.sh"
  extra_environment = {
    host = each.key,
    role = each.value.role,
  }
}

resource "cloudflare_record" "server_name" {
  for_each = local.cluster_hosts

  name    = each.key
  type    = "A"
  zone_id = data.cloudflare_zone.betasektionen.id
  value   = hcloud_server.cluster_hosts[each.key].ipv4_address
}

resource "cloudflare_record" "server_wildcard" {
  for_each = local.cluster_hosts

  name    = "*.${each.key}"
  type    = "A"
  zone_id = data.cloudflare_zone.betasektionen.id
  value   = hcloud_server.cluster_hosts[each.key].ipv4_address
}

resource "sshkey_ed25519_key_pair" "bootstrap" {
  comment = "dsekt-infra-boostrap"
}

resource "hcloud_ssh_key" "bootstrap" {
  name       = "dsekt-infra-bootstrap"
  public_key = sshkey_ed25519_key_pair.bootstrap.public_key
}

# This should depend on everything that's needed for the nomad cluster to be ready for getting it's
# ACL bootstrapped. The resources referenced here will be created when running with
# `-target='random_pet.stage1_nomad_cluster'` even though the result will just become the empty
# string.
resource "random_pet" "stage1_nomad_cluster" {
  keepers = {
    _ = substr(join(",", concat(
      [for name, _ in local.cluster_hosts : cloudflare_record.server_name[name].value],
      [for name, _ in local.cluster_hosts : cloudflare_record.server_wildcard[name].value],
      [for name, _ in local.cluster_hosts : module.nixos_install[name].result.out],
    )), 0, 0)
  }
}
