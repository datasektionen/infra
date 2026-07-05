{ pkgs, ... }:
{
  users.mutableUsers = false;

  users.users.viktoe = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeGrsaYii/5yiM3hL3DUGanxTWCaw9+rsvYLDJcj/en ekby@laptop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIgXz9nG1X3rA3LK5djAgE/FBv7tDIJZ8G07pHKDoSe6 viktoe@datasektionen.se"
    ];
    hashedPassword = "$6$4EBcX90yrnAQBnFf$84Sz2ZnarQljfdwLKYO3ZjeMq4MRVTM3EWtuILr1QsDsYnXXafHEh7yM145MpswQTqoc2Surh7BseTT4Ki4ML0";
    shell = pkgs.zsh;
  };

  users.users.osen = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICDbk+jGRrhHKrGyLxEqoMFAXngWyX3xGulpHF1iiRdW oskar@Oskars-MacBook-Air.local"
    ];
    hashedPassword = "$2y$05$17FdPswVL2vg/N3YKKGPw.KrZ7JCRSZGqtAVnSHukofRB2WRZ/Kzu";
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
  users.groups.deploy = { };
}
