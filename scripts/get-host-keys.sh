#!/bin/sh

set -euo pipefail

secrets="$OLDPWD/secrets"

encrypted_host_key_path="$secrets/${host}_ssh_host_ed25519_key.age"
if [ -f "$encrypted_host_key_path" ]; then
    mkdir -p ./etc/ssh

    age -d -i "$AGE_IDENTITY" -o ./etc/ssh/ssh_host_ed25519_key "$encrypted_host_key_path"
    chmod 600 ./etc/ssh/ssh_host_ed25519_key

    public_key=$(awk -F'"' "/^\s*$host =/{print \$2}" "$secrets/secrets.nix")
    echo "$public_key root@$host" > ./etc/ssh/ssh_host_ed25519_key.pub
fi
