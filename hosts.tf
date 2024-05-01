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
  all_hosts = merge(
    { for name, instance in hcloud_server.cluster_servers: name => { instance = instance, role = "server" } },
    { for name, instance in hcloud_server.cluster_clients: name => { instance = instance, role = "client" } },
  )
}

module "nixos_install" {
  for_each = local.all_hosts

  source                 = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${each.key}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.key}.config.system.build.diskoScript"

  target_host = each.value.instance.ipv4_address
  instance_id = each.value.instance.id

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
  for_each = local.all_hosts

  name    = each.key
  type    = "A"
  zone_id = data.cloudflare_zone.betasektionen.id
  value   = each.value.instance.ipv4_address
}

resource "cloudflare_record" "server_wildcard" {
  for_each = local.all_hosts

  name    = "*.${each.key}"
  type    = "A"
  zone_id = data.cloudflare_zone.betasektionen.id
  value   = each.value.instance.ipv4_address
}

resource "sshkey_ed25519_key_pair" "bootstrap" {
  comment = "dsekt-infra-boostrap"
}

resource "hcloud_ssh_key" "bootstrap" {
  name       = "dsekt-infra-bootstrap"
  public_key = sshkey_ed25519_key_pair.bootstrap.public_key
}
