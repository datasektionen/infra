{ pkgs, ... }:
{
  users.mutableUsers = false;

  users.users.mathm = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPC69ml72mqbn7L3QkpsCJuWdrKFYFNd0MaS5xERbuSF mathm-desktop"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEdUe7mxGdV/Q37RKndPzDHisFb7q/xm+L97jcGluSDOA8MGt/+wTxpyGxfyEqaMvwV2bakaMVHTB3711dDu5kE= mathm5nfc"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLZ6OVyjTvWx9gvS+/DvkQW5VvLBbykq/0AV5mYDLADDtIOaDVscQ3lGOcUsga1ODNSl14MSV63bE8VtHfG1HOc= mathm5nano"
    ];
    hashedPassword = "$y$j9T$JKUgC8EQsXkh08UQaB/ZA1$SH/lW5hNQqgHfhIdB/8si3tWpwYMy4gm6GgV6CcaWxC";
    shell = pkgs.fish;
  };

  users.users.rmfseo = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG5LP3Zg7IfsuPElwU/QTYG1Mz5WROTKP7h4cT2MQeza raf@amsterdam"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOwaEu0TGRXhxjk1+Pz2LP66Vfvvgr3IvxkRfkcRiP0Y raf@rotterdam"
    ];
    hashedPassword = "$y$j9T$wGjTUbozJn.GeZyKWYgBc/$U9zB.YZUX5jbmN429t46UmLeFp/CNMf1GMoKOFoUG25";
    shell = pkgs.zsh;
  };

  # for GitHub actions
  users.users.deploy = {
    isNormalUser = true;
    group = "deploy";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeUB4ftByjQKLMG2cADvuwr0DU+rD+CNCstrSyzCzG+ deploy@infra-gh"
    ];
    shell = pkgs.bash;
  };
  users.groups.deploy = {};
}
