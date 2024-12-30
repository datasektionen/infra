{
  config,
  secretsDir,
  pkgs,
  ...
}:
let
  internalHostname = "mediawiki.dsekt.internal";
in
{
  services.mediawiki = {
    enable = true;
    url = "https://wiki.datasektionen.se";
    name = "Datasektionen Wiki";
    extensions = {
      OpenIDConnect = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/OpenIDConnect-REL1_42-6c28c16.tar.gz";
        hash = "sha256-X5kUuvxINbuXaLMKRcLOl2L3qbnMT72lg2NA3A9Daj8=";
      };
      PluggableAuth = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_42-1da98f4.tar.gz";
        hash = "sha256-5uBUy7lrr86ApASYPWgF6Wa09mxxP0o+lXLt1gVswlA=";
      };
      VisualEditor = null;
    };
    extraConfig = ''
      $wgPluggableAuth_EnableAutoLogin = true;
      $wgPluggableAuth_Config[] = [
        "plugin" => "OpenIDConnect",
        "data" => [
          "providerURL" => "https://sso.datasektionen.se/op",
          "clientID" => "T7WAU9j3Pk-kle9BxAneMQvCg7oFbqgcR8j-zljYQVA=",
          "clientsecret" => trim(file_get_contents("${config.age.secrets.mediawiki-sso-client-secret.path}")),
          "scope" => ["openid", "profile", "email", "pls_wiki"],
        ],
        "groupsyncs" => [
          [
            "type" => "mapped",
            "map" => [
              "bureaucrat" => [ "pls_wiki" => "bureaucrat" ], // jag älskar byråkrati
            ],
          ]
        ],
      ];
      $wgOpenIDConnect_UseRealNameAsUserName = true;

      // $wgDebugToolbar = true;
    '';
    passwordSender = "d-sys@datasektionen.se";
    webserver = "nginx";
    nginx.hostName = internalHostname;
    # NOTE: this is not even usable since you can't login with username/password with the OIDC plugin, but it is required
    passwordFile = config.age.secrets.mediawiki-password.path;
  };

  services.nginx.virtualHosts.${internalHostname} = {
    listen = [
      {
        addr = config.dsekt.addresses.hosts.self;
        port = 3141;
      }
    ];
    extraConfig = ''
      absolute_redirect off;
    '';
  };

  # TODO: this only works when this is running on the same server as profiles.traefik-external
  services.traefik.dynamicConfigOptions.http = {
    routers.mediawiki = {
      rule = "Host(`wiki.datasektionen.se`)";
      service = "mediawiki";
      tls.certresolver = "default";
    };
    services.mediawiki.loadBalancer = {
      servers = [ { url = "http://${internalHostname}:3141"; } ];
    };
  };

  # TODO: backup uploads dir & mysql database

  age.secrets.mediawiki-sso-client-secret = {
    file = secretsDir + "/mediawiki-sso-client-secret.age";
    owner = "mediawiki";
    group = "nogroup";
    mode = "400";
  };
  age.secrets.mediawiki-password = {
    file = secretsDir + "/mediawiki-password.age";
    owner = "mediawiki";
    group = "nogroup";
    mode = "400";
  };
}
