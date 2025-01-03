{ config, lib, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableJIT = true;
    enableTCPIP = true;
    authentication = ''
      host all all ${config.dsekt.addresses.subnet} md5
      host all all 172.16.0.0/12 md5 # allow connections from docker (well, all class C private networks)

      local all all      peer map=m
    '';
    # Allow all unix users in the group `wheel` to authenticate as any database
    # user. (Since they can become root this is only for convenience). Also
    # allow any unix user to authenticate as the database user with the same
    # name, which is the case by default, but not when you add this `identMap`.
    identMap = ''
      ${lib.concatMapStringsSep "\n" (name: ''
        m ${name} all
      '') config.users.groups.wheel.members}
      m /^(.*)$ \1
    '';
    settings = {
      max_connections = 400;
    };
  };
  networking.firewall.allowedTCPPorts = [ 5432 ];
}
