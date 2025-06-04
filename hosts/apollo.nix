{ profiles, ... }:
{
  imports = with profiles; [
    hetzner-cloud
    base
    nomad.client
    traefik
  ];

  dsekt.nomad.volumes.host.planka = {
    userId = 1000;
    dirs = [
      "user-avatars"
      "background-images"
      "favicons"
      "attachments"
    ];
  };

  # Change this if you want to lose all data on this machine!
  system.stateVersion = "24.11";
}
