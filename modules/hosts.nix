{ config, lib, ... }:
with lib;
let
  ro =
    type:
    mkOption {
      inherit type;
      readOnly = true;
    };
in
{
  options.dsekt.hosts = ro (
    types.attrsOf (
      types.submodule {
        options = {
          privateAddr = ro types.str;
          wireguard = {
            publicKey = ro types.str;
            publicAddr = mkOption {
              type = types.nullOr types.str;
              readOnly = true;
              default = null;
            };
          };
        };
      }
    )
  );

  config.dsekt.hosts = lib.fix (self: {
    self = self.${config.networking.hostName};

    zeus = {
      privateAddr = "10.83.0.2";
      wireguard = {
        publicKey = "LEQ8lB86aK6tfKE2ppsz7raYs69Y1kZsc8O1hnatIms=";
        publicAddr.host = "home.magnusson.space";
      };
    };
    poseidon = {
      privateAddr = "10.83.0.3";
      wireguard.publicKey = "FqwkR+gKe/0JfFn3oXyyNDK8qh3LGMQw/t1pvGEHTBk=";
    };
    hades = {
      privateAddr = "10.83.0.4";
      wireguard = {
        publicKey = "mhGuL7fW63TnXHXNTTmT0Ij3hdEGMRCruxW5jbC5rC8=";
        publicAddr.host = "home.magnusson.space";
        publicAddr.port = 51801;
      };
    };
    ares = {
      privateAddr = "10.83.0.5";
      wireguard.publicKey = "eOgdM3olJsYQUFkhgRTV4yB6Wx5f+qQyfbkIuzcKen4=";
    };
    artemis = {
      privateAddr = "10.83.0.6";
      wireguard.publicKey = "Kzu4B/NoTD9o7ZnmPC/blwOEkxRZaxtjD1WYadJA9EE=";
    };
  });
}
