{ lib, ... }:
{
  options.dsekt.addresses.public = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    readOnly = true;
  };
  options.dsekt.addresses.private = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    readOnly = true;
  };

  config.dsekt.addresses.public = {
    cluster-servers = [ "zeus.betasektionen.se" "poseidon.betasektionen.se" "hades.betasektionen.se" ];
  };
  config.dsekt.addresses.private = {
    cluster-servers = [ "10.83.0.2" "10.83.0.3" "10.83.0.4" ];
  };
}
