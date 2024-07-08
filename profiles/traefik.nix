{ config, pkgs, secretsDir, ... }:
{
  services.traefik = {
    enable = true;
    environmentFiles = [
      config.age.secrets.nomad-traefik-acl-token.path
      config.age.secrets.cloudflare-dns-api-token.path
      (pkgs.writeText "traefik-cloudflare-config" "CLOUDFLARE_EMAIL=d-sys@datasektionen.se")
    ];
    staticConfigOptions = {
      api.dashboard = true;
      entryPoints.web = {
        address = ":443";
        asDefault = true;
      };
      entryPoints.web-internal.address = "${config.dsekt.addresses.hosts.self}:80";
      entryPoints.mattermost-calls-tcp.address = ":8443/tcp";
      entryPoints.mattermost-calls-udp.address = ":8443/udp";
      entryPoints.httpredirect = {
        # This port is also used by the web-internal entrypoint, so we need to bind to only the public address.
        address = "${config.networking.hostName}.datasektionen.se:80";
        http.redirections.entryPoint = {
          to = "websecure";
          scheme = "https";
          permanent = "true";
        };
      };

      log.level = "INFO";
      accessLog = { };

      providers.nomad = {
        exposedByDefault = false;
        endpoint = {
          address = "https://127.0.0.1:4646";
          token = "\${NOMAD_TOKEN}";
          tls.ca = "${../files/nomad-agent-ca.pem}";
        };
        # TODO: get all namespaces dynamically, e.g. using `nomad namespace list -json | jq '.[].Name' -r`
        namespaces = [ "default" "mattermost" "auth" ];
      };

      certificatesresolvers.default.acme = {
        # Good for testing: caserver = "https://acme-staging-v02.api.letsencrypt.org/directory";
        email = "d-sys@datasektionen.se";
        storage = config.services.traefik.dataDir + "/acme.json";
        dnschallenge = {
          provider = "cloudflare";
          resolvers = [ "1.1.1.1:53" ];
        };
      };
    };
    dynamicConfigOptions = {
      http = {
        routers.api = {
          rule = "Host(`traefik.datasektionen.se`)";
          service = "api@internal";
          middlewares = [ "auth" ];
          tls.certresolver = "default";
        };
        # Temporary, use something better in the future
        middlewares.auth.basicAuth.users = [
          "mathm:$2y$05$/.Sr1SoOYhGDHK0j7lE37eazHgqHM52eas0QF96EzvJfk6ma5XCzK"
        ];
        routers.nomad = {
          rule = "Host(`nomad.datasektionen.se`)";
          service = "nomad";
          tls.certresolver = "default";
        };
        services.nomad.loadBalancer = {
          servers = [{ url = "https://127.0.0.1:4646"; }];
          serversTransport = "nomadTransport";
        };
        serversTransports.nomadTransport.rootCAs = "${../files/nomad-agent-ca.pem}";
      };
      tls.stores.default.defaultGeneratedCert = {
        resolver = "default";
        domain = {
          main = "datasektionen.se";
          sans = [ "*.datasektionen.se" ];
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 8443 ];
  networking.firewall.allowedUDPPorts = [ 8443 ];

  age.secrets.nomad-traefik-acl-token.file = secretsDir + "/nomad-traefik-acl-token.env.age";
  age.secrets.cloudflare-dns-api-token.file = secretsDir + "/cloudflare-dns-api-token.env.age";
}
