{
  config,
  profiles,
  secretsDir,
  ...
}:
{
  imports = [ profiles.nomad.shared ];

  services.nomad = {
    dropPrivileges = false;
    enableDocker = true;
    settings = {
      client = {
        enabled = true;
        server_join.retry_join = config.dsekt.addresses.groups.cluster-servers;
        network_interface = "{{ GetPrivateInterfaces | include `address` `10[.]83[.]` | attr `name` }}";
      };
      plugin.docker = [
        { config = [ { auth = [ { config = config.age.secrets.nomad-docker-auth.path; } ]; } ]; }
      ];
    };
  };

  age.secrets.nomad-docker-auth.file = secretsDir + "/nomad-docker-auth.json.age";
}
