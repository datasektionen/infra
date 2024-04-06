#!/bin/sh

set -euo pipefail

repo="$OLDPWD"

# Get saved host keys
encrypted_host_key_path="$repo/secrets/${host}_ssh_host_ed25519_key.age"
if [ -f "$encrypted_host_key_path" ]; then
    mkdir -p ./etc/ssh

    age -d -i "$AGE_IDENTITY" -o ./etc/ssh/ssh_host_ed25519_key "$encrypted_host_key_path"
    chmod 600 ./etc/ssh/ssh_host_ed25519_key

    public_key=$(awk -F'"' "/^\s*$host =/{print \$2}" "$repo/secrets/secrets.nix")
    echo "$public_key root@$host" > ./etc/ssh/ssh_host_ed25519_key.pub
fi

if [ -n "$role" ]; then
    DONT_MOVE=1 $repo/scripts/provision-cert.sh "$role" "$host"

    mkdir -p ./var/lib/consul-certs

    mv nomad-consul-cert.pem nomad-consul-key.pem ./var/lib/consul-certs
fi
