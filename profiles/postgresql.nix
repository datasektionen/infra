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
    path = with pkgs; [ consul curl jq envoy ];
    script = ''
      consul services register $SERVICE_CONFIG
      port=$(curl \
        --cacert $CACERT \
        -H "X-Consul-Token: $CONSUL_HTTP_TOKEN" \
        "https://localhost:8501/v1/agent/service/$SERVICE_ID-sidecar-proxy" \
        | jq '.Port')
      consul connect envoy -sidecar-for=$SERVICE_ID -admin-bind=0.0.0.0:19000
    '';
    preStop = ''
      consul services deregister $SERVICE_CONFIG
    '';
  };
}
