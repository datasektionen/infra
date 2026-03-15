locals {
  hosts = {
    meta-tv = { role = "client", private_ip_addr = "10.83.1.3"}
  }
}

resource "null_resource" "bare_metal_install" {
  for_each = local.hosts

  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
NIX_SSHOPTS="-J ${var.ssh_user}@hades.datasektionen.se" nixos-rebuild \
  --target-host ${var.ssh_user}@meta-tv.dsekt.internal \
  --sudo \
  --flake .#meta-tv switch
EOT
  }
}
