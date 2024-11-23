{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
    traefik
  ];

  services.nomad.settings.client.host_volume = {
    "vault/data" = {
      path = "/var/lib/nomad-volumes/vault/data";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/nomad-volumes 0500 0 0"
    "d /var/lib/nomad-volumes/vault/data 0700 0 0" # vaultwarden runs as root
  ];

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "24.05";
}
