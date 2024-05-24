{ config, secretsDir, ... }:
{
  dsekt.services.traefik.servers.external = {
    environmentFiles = [ config.age.secrets.nomad-traefik-acl-token.path ];
    staticConfigOptions = {
      api.dashboard = true;
      entryPoints.web = {
        # This port is also used by traefik.internal, so we need to bind to only the public address.
        address = "${config.networking.hostName}.betasektionen.se:80";
        http.redirections.entryPoint = {
          to = "websecure";
          scheme = "https";
          permanent = "true";
        };
      };
      entryPoints.websecure.address = ":443";
      entryPoints.mattermost-calls-tcp.address = ":8443/tcp";
      entryPoints.mattermost-calls-udp.address = ":8443/udp";

      log.level = "INFO";
      accessLog = { };

      providers.nomad = {
        exposedByDefault = false;
        endpoint = {
          address = "https://127.0.0.1:4646";
          token = "\${NOMAD_TOKEN}";
          tls.ca = "${../../files/nomad-agent-ca.pem}";
        };
        prefix = "traefik-external";
        # TODO: get all namespaces dynamically, e.g. using `nomad namespace list -json | jq '.[].Name' -r`
        # NOTE: keep in sync with the same option in internal.nix
        namespaces = [ "default" "mattermost" ];
      };

      certificatesResolvers.default.acme = {
        email = "d-sys@datasektionen.se";
        storage = config.dsekt.services.traefik.servers.external.dataDir + "/acme.json";
        httpChallenge.entryPoint = "web";
      };
    };
    dynamicConfigOptions = {
      http = {
        routers.api = {
          rule = "Host(`traefik.betasektionen.se`)";
          service = "api@internal";
          middlewares = [ "auth" ];
          tls.certResolver = "default";
          entrypoints = [ "websecure" ];
        };
        # Temporary, use something better in the future
        middlewares.auth.basicAuth.users = [
          "mathm:$2y$05$/.Sr1SoOYhGDHK0j7lE37eazHgqHM52eas0QF96EzvJfk6ma5XCzK"
        ];
        routers.nomad = {
          rule = "Host(`nomad.betasektionen.se`)";
          service = "nomad";
          tls.certResolver = "default";
          entrypoints = [ "websecure" ];
        };
        services.nomad.loadBalancer = {
          servers = [{ url = "https://127.0.0.1:4646"; }];
          serversTransport = "nomadTransport";
        };
        serversTransports.nomadTransport.rootCAs = "${../../files/nomad-agent-ca.pem}";
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 8443 ];
  networking.firewall.allowedUDPPorts = [ 8443 ];

  age.secrets.nomad-traefik-acl-token.file = secretsDir + "/nomad-traefik-acl-token.env.age";
}
