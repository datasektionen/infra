{ config, pkgs, ... }:
let
  consulServiceId = "postgresql-${config.networking.hostName}";
  consulServiceConfig = (pkgs.formats.json { }).generate "postgresql-service.json" {
    service = {
      id = consulServiceId;
      name = "postgresql";
      port = 5432;
      checks = [{
        tcp = "localhost:5432";
        interval = "20s";
      }];
      connect.sidecar_service = { };
    };
  };
in
{
  services.postgresql = {
    enable = true;
    enableJIT = true;
  };

  systemd.services.postgresql-sidecar-proxy = {
    requires = [ "postgresql.service" "consul.service" ];
    requiredBy = [ "postgresql.service" ];
    serviceConfig.EnvironmentFile = config.age.secrets.consul-admin-token.path;
    environment = {
      SERVICE_CONFIG = consulServiceConfig;
      SERVICE_ID = consulServiceId;
      CACERT = ../files/consul-agent-ca.pem;
    };
    path = with pkgs; [ consul docker curl jq ];
    script = ''
      consul services register $SERVICE_CONFIG
      port=$(curl \
        --cacert $CACERT \
        -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" \
        "https://localhost:8501/v1/agent/service/$SERVICE_ID-sidecar-proxy" \
        | jq '.Port')

      # It's important here that the directory isn't world readable, since the
      # configuration file contains secrets. The file itself must be, since
      # envoy runs as non-root in its container and it must be able to read it.
      config=$(mktemp -d)
      consul connect envoy -bootstrap -sidecar-for=$SERVICE_ID > $config/envoy.json
      chmod 644 $config/envoy.json
      exec docker run --rm \
        --name=$SERVICE_ID-sidecar-proxy \
        -v"$config/envoy.json:/envoy.json" \
        --network=host \
        envoyproxy/envoy:v1.26.8  \
        -c /envoy.json
    '';
    # TODO: get envoy version from consul/nomad, since that should be a
    # supported version we don't need to keep track of manually here
    preStop = ''
      consul services deregister $SERVICE_CONFIG
    '';
  };
}
