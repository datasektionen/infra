{ config, profiles, ... }:
{
  imports = [ profiles.nomad.shared ];

  services.nomad = {
    dropPrivileges = false;
    enableDocker = true;
    settings.client = {
      enabled = true;
      server_join.retry_join = config.dsekt.addresses.groups.cluster-servers;
      network_interface = "{{ GetPrivateInterfaces | include `address` `10[.]83[.]` | attr `name` }}";
    };
  };
}
