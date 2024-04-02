{ lib, ... }:
{
  options.dsekt.addresses = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    readOnly = true;
  };

  config.dsekt.addresses = {
    cluster-servers = [ "zeus.betasektionen.se" "poseidon.betasektionen.se" "hades.betasektionen.se" ];
  };
}
