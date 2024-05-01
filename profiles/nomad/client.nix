{ config, profiles, ... }:
{
  imports = [ profiles.nomad.shared ];

  services.nomad = {
    dropPrivileges = false;
    enableDocker = true;
    settings = {
      client = {
        enabled = true;
        server_join.retry_join = config.dsekt.addresses.private.cluster-servers;
      };
    };
  };
}
