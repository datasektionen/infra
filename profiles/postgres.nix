{ config, ... }:
{
  services.postgresql = {
    enable = true;
    enableJIT = true;
    enableTCPIP = true;
    authentication = ''
      host all all ${config.dsekt.addresses.subnet} md5
      host all all 172.16.0.0/12 md5 # allow connections from docker (well, all class C private networks)
    '';
    settings = {
      max_connections = 400;
    };
  };
  networking.firewall.allowedTCPPorts = [ 5432 ];
}
