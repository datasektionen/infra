let
  mathm = [
    "age1yubikey1q2gkk5zhme43j9mzv8pyd22d60vv5v73aupcqw09fz8apwhw4qw3yd3n0w5"
    "age1yubikey1qtppenqpqjtll78q0tfcgnm4dczy7nakmj5l2z3syyqfcq27kqx32hh72rt"
  ];

  artemis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGbzS7zU/PTWtsXhBymFN570ZPU1c2OenEy6+rXjWoC";
  zeus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAkpV+cZwuMbo/v1iSBMvBThnVoSnY8qxlUU9/wHtrmh";
  poseidon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKepaQJNM9zJO/MkX9yju1urpYouTSElz1M01lCeH3Ef";
  hades = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCFb/uxJljnDlv7QZIqsV8HD337T7bJYWYkGXxf5WCn";
in
{
  # `encrypt = "base64keythatis32byteslong"`
  "consul-gossip-key.hcl.age".publicKeys = mathm ++ [ zeus poseidon hades ];
  # `CONSUL_HTTP_TOKEN=uuid`
  "nomad-consul-token.env.age".publicKeys = mathm ++ [ zeus poseidon hades ];
  # `{"server":{"encrypt":"base64urlkeythatis32byteslong"}}`
  "nomad-gossip-key.json.age".publicKeys = mathm ++ [ zeus poseidon hades ];

  # `AUTHENTIK_POSTGRESQL__PASSWORD=...`
  "authentik-postgres-password.env.age".publicKeys = mathm ++ [ artemis ];
  # `AUTHENTIK_SECRET_KEY=base64string`
  "authentik-secret-key.env.age".publicKeys = mathm ++ [ artemis ];
  # `AUTHENTIK_EMAIL__USERNAME=string\nAUTHENTIK_EMAIL__PASSWORD=string`
  "authentik-email-credentials.env.age".publicKeys = mathm ++ [ artemis ];

  "zeus_ssh_host_ed25519_key.age".publicKeys = mathm;
  "poseidon_ssh_host_ed25519_key.age".publicKeys = mathm;
  "hades_ssh_host_ed25519_key.age".publicKeys = mathm;
}

