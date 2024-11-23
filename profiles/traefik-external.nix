{
  config,
  pkgs,
  secretsDir,
  profiles,
  ...
}:
{
  imports = [ profiles.traefik ];

  services.traefik = {
    environmentFiles = [
      config.age.secrets.cloudflare-dns-api-token.path
      (pkgs.writeText "traefik-cloudflare-config" "CLOUDFLARE_EMAIL=d-sys@datasektionen.se")
    ];
    staticConfigOptions = {
      entryPoints.mattermost-calls-tcp.address = ":8443/tcp";
      entryPoints.mattermost-calls-udp.address = ":8443/udp";
      entryPoints.web = {
        address = ":443";
        asDefault = true;
      };
      entryPoints.httpredirect = {
        # This port is also used by the web-internal entrypoint, so we need to bind to only the public address.
        address = "${config.networking.hostName}.datasektionen.se:80";
        http.redirections.entryPoint = {
          to = "web";
          scheme = "https";
          permanent = "true";
        };
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
        routers.api-external = {
          rule = "Host(`traefik.datasektionen.se`)";
          service = "api@internal";
          middlewares = [ "auth" ];
          tls.certresolver = "default";
        };
        routers.nomad = {
          rule = "Host(`nomad.datasektionen.se`)";
          service = "nomad";
          tls.certresolver = "default";
        };
        services.nomad.loadBalancer = {
          servers = [ { url = "https://${config.networking.hostName}.dsekt.internal:4646"; } ];
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
  networking.firewall.allowedTCPPorts = [
    80
    443
    8443
  ];
  networking.firewall.allowedUDPPorts = [ 8443 ];

  age.secrets.cloudflare-dns-api-token.file = secretsDir + "/cloudflare-dns-api-token.env.age";
}
