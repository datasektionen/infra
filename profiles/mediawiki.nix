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
      # NOTE: these links disappear if they change the commit hash for a version or remove a
      # version. Check <https://extdist.wmflabs.org/dist/extensions/> and copy links from there.
      # RELX_YZ specifies the version of mediawiki they're made for and you can check which one
      # we're running using e.g. `nix eval '.#nixosConfigurations.ares.pkgs.mediawiki.version'`.
      # They do however get cached pretty well since we specify the hash so it should take a while
      # before it breaks (which is even worse).
      OpenIDConnect = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/OpenIDConnect-REL1_44-438d993.tar.gz";
        hash = "sha256-TpFEToogaN76Ll6jkbU0CMfNQT/+Zl7xny8woPr7Oh8=";
      };
      PluggableAuth = pkgs.fetchzip {
        url = "https://extdist.wmflabs.org/dist/extensions/PluggableAuth-REL1_44-9cf6960.tar.gz";
        hash = "sha256-jx3Pw4jZ86WO0jwNyIBguNLCpwzxKEDJDAzm5I7YtNM=";
      };
      VisualEditor = null;
    };
    extraConfig = ''
      $wgPluggableAuth_EnableAutoLogin = true;
      $wgPluggableAuth_Config[] = [
        "plugin" => "OpenIDConnect",
        "data" => [
          "providerURL" => "https://sso.datasektionen.se/op",
          "clientID" => "wiki",
          "clientsecret" => trim(file_get_contents("${config.age.secrets.mediawiki-sso-client-secret.path}")),
          "scope" => ["openid", "profile", "email", "permissions_flat"],
        ],
        "groupsyncs" => [
          [
            "type" => "mapped",
            "map" => [
              "bureaucrat" => [ "permissions_flat" => "bureaucrat" ], // jag ÄLSKAR byråkrati
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

  # WARN: this only works when this is running on the same server as profiles.traefik-external
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

  dsekt.restic = {
    # TODO: not sure if this works
    backupPrepareCommand = ''
      ${pkgs.sudo}/bin/sudo -u mysql ${config.services.mysql.package}/bin/mysqldump --all-databases > /root/mysql_dump.sql
    '';

    paths = [
      config.services.mediawiki.uploadsDir
      "/root/mysql_dump.sql"
    ];
  };

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
