{ config, ... }:
{
  virtualisation.oci-containers.containers.authentik-server = {
    image = "ghcr.io/goauthentik/server:2024.2.2";
    cmd = [ "server" ];
    environment = {
      AUTHENTIK_REDIS__HOST = "host.docker.internal";
      AUTHENTIK_REDIS__PASSWORD = "authentik";
      AUTHENTIK_REDIS__PORT = toString config.services.redis.servers.authentik.port;
      AUTHENTIK_POSTGRESQL__HOST = "host.docker.internal";
      AUTHENTIK_POSTGRESQL__USER = "authentik";
      AUTHENTIK_POSTGRESQL__NAME = "authentik";
    };
    environmentFiles = [
      config.age.secrets.authentik-postgres-password.path
      config.age.secrets.authentik-secret-key.path
    ];
    volumes = [
      "authentik-media:/media"
      "authentik-templates:/templates"
    ];
    ports = [ "9000:9000" "9443:9443" ];
  };

  virtualisation.oci-containers.containers.authentik-worker = {
    image = "ghcr.io/goauthentik/server:2024.2.2";
    cmd = [ "worker" ];
    environment = {
      AUTHENTIK_REDIS__HOST = "host.docker.internal";
      AUTHENTIK_REDIS__PASSWORD = "authentik";
      AUTHENTIK_REDIS__PORT = toString config.services.redis.servers.authentik.port;
      AUTHENTIK_POSTGRESQL__HOST = "host.docker.internal";
      AUTHENTIK_POSTGRESQL__USER = "authentik";
      AUTHENTIK_POSTGRESQL__NAME = "authentik";
    };
    environmentFiles = [
      config.age.secrets.authentik-postgres-password.path
      config.age.secrets.authentik-secret-key.path
    ];
    user = "root";
    volumes = [
      "authentik-media:/media"
      "authentik-templates:/templates"
      "authentik-certs:/certs"
    ];
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "authentik" ];
    ensureUsers = [ { name = "authentik"; ensureDBOwnership = true; } ];
    enableTCPIP = true;
    authentication = ''
      host authentik authentik 10.88.0.0/16 trust
    '';
  };

  systemd.services.postgresql-set-authentik-password = {
    serviceConfig.Type = "oneshot";
    requiredBy = [ "podman-authentik-server.service" "podman-authentik-worker.service" ];
    after = ["postgresql.service"];
    path = [ config.services.postgresql.package ];
    script = ''
      source ${config.age.secrets.authentik-postgres-password.path}
      echo "ALTER ROLE authentik WITH ENCRYPTED PASSWORD '$AUTHENTIK_POSTGRESQL__PASSWORD';" | \
        /run/wrappers/bin/sudo -u postgres psql -U postgres
    '';
  };

  services.redis.servers.authentik = {
    enable = true;
    port = 46379;
    requirePass = "authentik";
    bind = "10.88.0.1";
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [ 5432 80 443 ];

  services.nginx.enable = true;
  services.nginx.virtualHosts."login.artemis.betasektionen.se" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://localhost:9000";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults = {
      webroot = "/var/lib/acme/acme-challenge";
      email = "i-dont-want-emails@yeet-domain.com";
    };
  };
  users.users.nginx.extraGroups = [ "acme" ];

  # `AUTHENTIK_POSTGRESQL__PASSWORD=...`
  age.secrets.authentik-postgres-password.file = ../secrets/authentik-postgres-password.env.age;
  age.secrets.authentik-secret-key.file = ../secrets/authentik-secret-key.env.age;
}
