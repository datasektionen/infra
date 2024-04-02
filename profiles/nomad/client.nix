{ profiles, ... }:
{
  imports = [ profiles.nomad.shared ];

  services.nomad = {
    dropPrivileges = false;
    enableDocker = true;
    settings = {
      client.enabled = true;
    };
  };
}
