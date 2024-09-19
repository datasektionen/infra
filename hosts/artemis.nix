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
    "planka/avatars" = {
      path = "/var/lib/nomad-volumes/planka/avatars";
    };
    "planka/backgrounds" = {
      path = "/var/lib/nomad-volumes/planka/backgrounds";
    };
    "planka/attachments" = {
      path = "/var/lib/nomad-volumes/planka/attachments";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/nomad-volumes 0500 0 0"
    "d /var/lib/nomad-volumes/vault/data 0700 0 0" # vaultwarden runs as root

    "d /var/lib/nomad-volumes/planka/avatars 0750 1000 1000"
    "d /var/lib/nomad-volumes/planka/backgrounds 0750 1000 1000"
    "d /var/lib/nomad-volumes/planka/attachments 0750 1000 1000"
  ];

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "24.05";
}
