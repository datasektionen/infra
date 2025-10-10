#!/bin/sh

set -euo pipefail

function usage() {
    echo "Usage: $0 <server|client> <host>"
    exit 1
}

(( $# == 2 )) || usage
kind="$1"
host="$2"

case "$kind" in
    server) ;;
    client) ;;
    *) usage;;
esac

repo=$(realpath "$(dirname $0)/..")

[ -f "$repo/nomad-agent-ca-key.pem" ] || age -d -i "$AGE_IDENTITY" \
    -o "$repo/nomad-agent-ca-key.pem" "$repo/secrets/nomad-agent-ca-key.pem.age"

[ -f "global-server-nomad.pem" ] && echo "Found existing cert. Remove or rename it first!" && exit 1
[ -f "global-client-nomad.pem" ] && echo "Found existing cert. Remove or rename it first!" && exit 1

nomad tls cert create \
    -ca=$repo/files/nomad-agent-ca.pem -key=$repo/nomad-agent-ca-key.pem \
    -additional-dnsname="$host.datasektionen.se" -additional-dnsname="$host.dsekt.internal" \
    $([ "$kind" = "server" ] && echo "-server" || echo "-client")

mv global-$([ "$kind" = "server" ] && echo server || echo client)-nomad.pem \
    cert.pem
mv global-$([ "$kind" = "server" ] && echo server || echo client)-nomad-key.pem \
    key.pem

if [[ "${DONT_MOVE:-"0"}" == "0" ]]; then
    rsync --rsync-path="sudo rsync" --remove-source-files --chown=root:root \
        cert.pem key.pem \
        "$SSH_USER@$host.datasektionen.se":/var/lib/nomad-certs/
    echo "Success! New cert moved to remote server"
    echo "    Hint: just restart the Nomad daemon now and all should work"
fi
