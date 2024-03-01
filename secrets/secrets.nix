let
  mathm = [
    "age1yubikey1q2gkk5zhme43j9mzv8pyd22d60vv5v73aupcqw09fz8apwhw4qw3yd3n0w5"
    "age1yubikey1qtppenqpqjtll78q0tfcgnm4dczy7nakmj5l2z3syyqfcq27kqx32hh72rt"
  ];

  artemis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbs8rhtszom2dNh/rxwH6fXAQVfgS4e6+1kE4OPOBb0";
in
{
  # must be formatted as `encrypt = "base64keythatis32byteslong"`
  "consul-gossip-key.hcl.age".publicKeys = mathm ++ [ artemis ];
}
