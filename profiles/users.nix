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
    ];
    hashedPassword = "$y$j9T$JKUgC8EQsXkh08UQaB/ZA1$SH/lW5hNQqgHfhIdB/8si3tWpwYMy4gm6GgV6CcaWxC";
    shell = pkgs.fish;
  };
}
