{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
    traefik
  ];

  dsekt.nomad.volumes.host.vault = {
    userId = 0; # vaultwarden runs as root
    dirs = [ "data" ];
  };

  dsekt.nomad.volumes.host.planka = {
    userId = 1000;
    dirs = [
      "user-avatars"
      "background-images"
      "favicons"
      "attachments"
    ];
  };

  dsekt.nomad.volumes.host.prometheus = {
    userId = 65534; # Runs as nobody?
    dirs = [ "data" ];
  };

  dsekt.nomad.volumes.host.apollo = {
    userId = 65533; # Runs as nobody?
    dirs = [ "data" ];
  };

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "24.11";
}
