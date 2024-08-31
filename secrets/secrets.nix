let
  sysadmins = [
    # mathm
    "age1yubikey1q2gkk5zhme43j9mzv8pyd22d60vv5v73aupcqw09fz8apwhw4qw3yd3n0w5"
    "age1yubikey1qtppenqpqjtll78q0tfcgnm4dczy7nakmj5l2z3syyqfcq27kqx32hh72rt"

    # rmfseo
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG5LP3Zg7IfsuPElwU/QTYG1Mz5WROTKP7h4cT2MQeza raf@amsterdam"
  ];

  zeus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAkpV+cZwuMbo/v1iSBMvBThnVoSnY8qxlUU9/wHtrmh";
  poseidon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKepaQJNM9zJO/MkX9yju1urpYouTSElz1M01lCeH3Ef";
  hades = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCFb/uxJljnDlv7QZIqsV8HD337T7bJYWYkGXxf5WCn";
  ares = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvT+r/mtIDTsTjccGXYpkA/3VQED9WHNU1NB9Hjh0Me";
in
{
  "zeus_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "poseidon_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "hades_ssh_host_ed25519_key.age".publicKeys = sysadmins;
  "ares_ssh_host_ed25519_key.age".publicKeys = sysadmins;

  # `{"server":{"encrypt":"base64urlkeythatis32byteslong"}}`
  "nomad-gossip-key.json.age".publicKeys = sysadmins ++ [
    zeus
    poseidon
    hades
  ];
  "nomad-agent-ca-key.pem.age".publicKeys = sysadmins;

  # `NOMAD_TOKEN=uuid-with-dashes`
  "nomad-traefik-acl-token.env.age".publicKeys = sysadmins ++ [ ares ];

  # `CLOUDFLARE_DNS_API_TOKEN=...`
  "cloudflare-dns-api-token.env.age".publicKeys = sysadmins ++ [ ares ];
}
