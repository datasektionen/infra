let
  sysadmins = [
    # mathm
    "age1yubikey1q2gkk5zhme43j9mzv8pyd22d60vv5v73aupcqw09fz8apwhw4qw3yd3n0w5"
    "age1yubikey1qtppenqpqjtll78q0tfcgnm4dczy7nakmj5l2z3syyqfcq27kqx32hh72rt"

    # rmfseo
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG5LP3Zg7IfsuPElwU/QTYG1Mz5WROTKP7h4cT2MQeza raf@amsterdam"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOwaEu0TGRXhxjk1+Pz2LP66Vfvvgr3IvxkRfkcRiP0Y raf@rotterdam"

    # viktoe
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHeGrsaYii/5yiM3hL3DUGanxTWCaw9+rsvYLDJcj/en ekby@laptop"
  ];

  zeus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAkpV+cZwuMbo/v1iSBMvBThnVoSnY8qxlUU9/wHtrmh";
  poseidon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKepaQJNM9zJO/MkX9yju1urpYouTSElz1M01lCeH3Ef";
  hades = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCFb/uxJljnDlv7QZIqsV8HD337T7bJYWYkGXxf5WCn";
  ares = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvT+r/mtIDTsTjccGXYpkA/3VQED9WHNU1NB9Hjh0Me";
  artemis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDiCbmT5XtIMKT62dmg/O+8x8kms6ELc7GCL9zeK8uTD";
  apollo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILiHIS7WraYSjBonICrCJqDaM6ROVLt65rMyEKhNWha2";

  nomadServers = [ zeus poseidon hades ];
  nomadClients = [ ares artemis apollo ];
in
{
  "zeus_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "poseidon_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "hades_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "ares_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "artemis_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "apollo_ssh_host_ed25519_key.age".publicKeys = sysadmins;

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

  "wireguard-preshared-key.age".publicKeys = sysadmins ++ [ hades ];
  # Public key: `BTpGRxLRjCYUiti/5A4uNvKYp0biNkA6PTV7Yck/NxM=`
  "wireguard-hades-private-key.age".publicKeys = sysadmins ++ [ hades ];

  # { "auths": { "ghcr.io": { "auth": "$(echo $username:$password | base64)" } } }
  # Password is a personal access token (classic) with `read:packages`.
  "nomad-docker-auth.json.age".publicKeys = sysadmins ++ nomadClients;

  # Plain text format
  "mediawiki-sso-client-secret.age".publicKeys = sysadmins ++ [ ares ];
  # This is not even usable since you can't login with username/password with the OIDC plugin, but it is required. Plain text format
  "mediawiki-password.age".publicKeys = sysadmins ++ [ ares ];
}
