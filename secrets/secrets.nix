let
  sysadmins = [
    # viktoe
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeGrsaYii/5yiM3hL3DUGanxTWCaw9+rsvYLDJcj/en ekby@laptop"

    # osen
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICDbk+jGRrhHKrGyLxEqoMFAXngWyX3xGulpHF1iiRdW oskar@Oskars-MacBook-Air.local"
  ];

  zeus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAkpV+cZwuMbo/v1iSBMvBThnVoSnY8qxlUU9/wHtrmh";
  ares = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvT+r/mtIDTsTjccGXYpkA/3VQED9WHNU1NB9Hjh0Me";
  athena = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIN/vUc3wJARnek+VX5JeopG2Xf+uam1OCuG40toQ02r";
  meta-tv = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5P9VvJd1FP1SaGb1fAuqezlFVEUZH4FBhCaFfu/DzS";

  nomadServers = [
    zeus
  ];
  nomadClients = [
    ares
    athena
    meta-tv
  ];
in
{
  "zeus_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "ares_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "athena_ssh_host_ed25519_key.age".publicKeys = sysadmins;

  # `{"server":{"encrypt":"base64urlkeythatis32byteslong"}}`
  "nomad-gossip-key.json.age".publicKeys = sysadmins ++ nomadServers;
  "nomad-agent-ca-key.pem.age".publicKeys = sysadmins;

  # `NOMAD_TOKEN=uuid-with-dashes`
  "nomad-traefik-acl-token.env.age".publicKeys = sysadmins ++ nomadClients;

  # `CLOUDFLARE_DNS_API_TOKEN=...`
  "cloudflare-dns-api-token.env.age".publicKeys = sysadmins ++ [ ares ];

  "restic-repo-pwd-ares.age".publicKeys = sysadmins ++ [ ares ];

  # `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `RESTIC_PASSWORD`
  "restic-s3-creds-ares.env.age".publicKeys = sysadmins ++ [ ares ];

  "wireguard-preshared-key.age".publicKeys = sysadmins ++ [ zeus meta-tv ];
  # Public key: `BTpGRxLRjCYUiti/5A4uNvKYp0biNkA6PTV7Yck/NxM=`
  "wireguard-zeus-private-key.age".publicKeys = sysadmins ++ [ zeus ];

  # Public key: `HibcPcaxmPs1QKSh97r2/CpLId0IkEo94pwgFvg+lXs=`
  "wireguard-meta-tv-private-key.age".publicKeys = sysadmins ++ [ meta-tv ];

  # { "auths": { "ghcr.io": { "auth": "$(echo $username:$password | base64)" } } }
  # Password is a personal access token (classic) with `read:packages`.
  "nomad-docker-auth.json.age".publicKeys = sysadmins ++ nomadClients;

  # Plain text format
  "mediawiki-sso-client-secret.age".publicKeys = sysadmins ++ [ ares ];
  # This is not even usable since you can't login with username/password with the OIDC plugin, but it is required. Plain text format
  "mediawiki-password.age".publicKeys = sysadmins ++ [ ares ];

  # Username and password for immich storagebox
  "immich-storagebox-credentials.age".publicKeys = sysadmins ++ nomadClients;

  # Username and password for immich storagebox
  "planka-storagebox-credentials.age".publicKeys = sysadmins ++ nomadClients;

  # Username and password for immich storagebox
  "apollo-storagebox-credentials.age".publicKeys = sysadmins ++ nomadClients;
}
