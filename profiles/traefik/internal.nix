{ config, secretsDir, ... }:
{
  dsekt.services.traefik.servers.internal = {
    environmentFiles = [ config.age.secrets.nomad-traefik-acl-token.path ];
    staticConfigOptions = {
      api.dashboard = true;
      entryPoints.web.address = "${config.dsekt.addresses.hosts.self}:80";

      log.level = "INFO";
      accessLog = { };

      providers.nomad = {
        exposedByDefault = false;
        endpoint = {
          address = "https://127.0.0.1:4646";
          token = "\${NOMAD_TOKEN}";
          tls.ca = "${../../files/nomad-agent-ca.pem}";
        };
        prefix = "traefik-internal";
        # NOTE: keep in sync with the same option in external.nix
        namespaces = [ "default" "mattermost" "auth" ];
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 ];

  age.secrets.nomad-traefik-acl-token.file = secretsDir + "/nomad-traefik-acl-token.env.age";
}
