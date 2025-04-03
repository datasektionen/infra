{ config, secretsDir, ... }:
let
  inherit (config.networking) hostName;
in
{
  services.traefik = {
    enable = true;
    environmentFiles = [ config.age.secrets.nomad-traefik-acl-token.path ];
    staticConfigOptions = {
      api.dashboard = true;
      entryPoints.web-internal.address = "${config.dsekt.addresses.hosts.self}:80";
      log.level = "INFO";
      accessLog = { };

      providers.nomad = {
        exposedByDefault = false;
        endpoint = {
          # We're making nomad bind to the internal IP address so we can't use
          # 127.0.0.1. We also can't use ${config.dsekt.addresses.hosts.self}
          # since the certificate isn't valid for that address.
          address = "https://${hostName}.dsekt.internal:4646";
          token = "\${NOMAD_TOKEN}";
          tls.ca = "${../files/nomad-agent-ca.pem}";
        };
        # TODO: get all namespaces dynamically, e.g. using `nomad namespace list -json | jq '.[].Name' -r`
        namespaces = [
          "auth"
          "ddagen"
          "default"
          "djulkalendern"
          "jml"
          "mattermost"
          "metaspexet"
          "twenty"
          "vault"
        ];
      };

    };
    dynamicConfigOptions = {
      http = {
        routers.api = {
          rule = "Host(`traefik.${hostName}.dsekt.internal`)";
          service = "api@internal";
          middlewares = [ "auth" ];
        };
        # Temporary, use something better in the future
        middlewares.auth.basicAuth.users = [
          "mathm:$2y$05$/.Sr1SoOYhGDHK0j7lE37eazHgqHM52eas0QF96EzvJfk6ma5XCzK"
          "rmfseo:$2y$05$PoyrRBezOjCyO6bVYx/L5e7/u3oSIUhZVTraMOc2AT8h7k/.S.I2y"
        ];
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 ];

  age.secrets.nomad-traefik-acl-token.file = secretsDir + "/nomad-traefik-acl-token.env.age";
}
