{ config, secretsDir, ... }:
{
  services.traefik = {
    enable = true;
    environmentFiles = [ config.age.secrets.nomad-traefik-acl-token.path ];
    staticConfigOptions = {
      entryPoints.web = {
        address = ":80";
        http.redirections.entryPoint = {
          to = "websecure";
          scheme = "https";
          permanent = "true";
        };
      };
      entryPoints.websecure.address = ":443";
      api.dashboard = true;

      log.level = "INFO";
      accessLog = { };

      providers.nomad = {
        exposedByDefault = false;
        endpoint = {
          address = "https://127.0.0.1:4646";
          token = "\${NOMAD_TOKEN}";
          tls.ca = "${../../files/nomad-agent-ca.pem}";
        };
      };

      certificatesResolvers.default.acme = {
        email = "d-sys@datasektionen.se";
        storage = config.services.traefik.dataDir + "/acme.json";
        httpChallenge.entryPoint = "web";
      };
    };
    dynamicConfigOptions = {
      http = {
        routers.api = {
          rule = "Host(`traefik.ares.betasektionen.se`)";
          service = "api@internal";
          middlewares = [ "auth" ];
          tls.certResolver = "default";
        };
        # Temporary, use something better in the future
        middlewares.auth.basicAuth.users = [
          "mathm:$2y$05$/.Sr1SoOYhGDHK0j7lE37eazHgqHM52eas0QF96EzvJfk6ma5XCzK"
        ];
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  age.secrets.nomad-traefik-acl-token.file = secretsDir + "/nomad-traefik-acl-token.env.age";
}
