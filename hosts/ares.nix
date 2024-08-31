{ lib, profiles, ... }:
let
  mattermost-dirs = [
    "config"
    "data"
    "logs"
    "plugins"
    "client/plugins"
    "bleve-indexes"
  ];
in
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
    postgres
    traefik
  ];

  services.nomad.settings.client.host_volume = lib.listToAttrs (
    lib.forEach mattermost-dirs (x: {
      name = "mattermost/${x}";
      value = {
        path = "/var/lib/mattermost/${x}";
      };
    })
  );
  systemd.tmpfiles.rules = lib.forEach mattermost-dirs (
    x: "d /var/lib/mattermost/${x} 0750 2000 2000"
  );

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "23.11";
}
