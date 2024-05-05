let
  mathm = [
    "age1yubikey1q2gkk5zhme43j9mzv8pyd22d60vv5v73aupcqw09fz8apwhw4qw3yd3n0w5"
    "age1yubikey1qtppenqpqjtll78q0tfcgnm4dczy7nakmj5l2z3syyqfcq27kqx32hh72rt"
  ];

  zeus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAkpV+cZwuMbo/v1iSBMvBThnVoSnY8qxlUU9/wHtrmh";
  poseidon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKepaQJNM9zJO/MkX9yju1urpYouTSElz1M01lCeH3Ef";
  hades = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCFb/uxJljnDlv7QZIqsV8HD337T7bJYWYkGXxf5WCn";
  ares = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOvT+r/mtIDTsTjccGXYpkA/3VQED9WHNU1NB9Hjh0Me";
in
{
  "zeus_ssh_host_ed25519_key.age".publicKeys = mathm;
  "poseidon_ssh_host_ed25519_key.age".publicKeys = mathm;
  "hades_ssh_host_ed25519_key.age".publicKeys = mathm;
  "ares_ssh_host_ed25519_key.age".publicKeys = mathm;

  # `{"server":{"encrypt":"base64urlkeythatis32byteslong"}}`
  "nomad-gossip-key.json.age".publicKeys = mathm ++ [ zeus poseidon hades ];
  "nomad-agent-ca-key.pem.age".publicKeys = mathm;

  # created with:
  # ```
  # nomad acl policy apply traefik-read-all-jobs ./profiles/traefik/policy.hcl
  # nomad acl token create -name="traefik" -policy=traefik-read-all-jobs
  # ```
  # `NOMAD_TOKEN=uuid-with-dashes`
  "nomad-traefik-acl-token.env.age".publicKeys = mathm ++ [ ares ];
}
