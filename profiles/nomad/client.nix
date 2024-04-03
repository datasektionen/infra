{ pkgs, profiles, ... }:
{
  imports = [ profiles.nomad.shared ];

  services.nomad = {
    dropPrivileges = false;
    enableDocker = true;
    settings = {
      client = {
        enabled = true;
        cni_path = "${pkgs.cni-plugins}/bin";
      };
    };
    extraPackages = with pkgs; [ consul ];
  };
}
