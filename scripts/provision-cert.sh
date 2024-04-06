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

[ -f "$repo/consul-agent-ca-key.pem" ] || age -d -i "$AGE_IDENTITY" \
    -o "$repo/consul-agent-ca-key.pem" "$repo/secrets/consul-agent-ca-key.pem.age"

[ -f "dc1-server-consul-0.pem" ] && echo "Found existing cert. Remove or rename it first!" && exit 1
[ -f "dc1-client-consul-0.pem" ] && echo "Found existing cert. Remove or rename it first!" && exit 1

consul tls cert create \
    -ca=$repo/files/consul-agent-ca.pem -key=$repo/consul-agent-ca-key.pem \
    -additional-dnsname="$host.betasektionen.se" \
    -additional-dnsname=$([ "$kind" = "server" ] && echo "server.global.nomad" || echo "client.global.nomad") \
    $([ "$kind" = "server" ] && echo -node="$host" -server || echo -client)

mv dc1-$([ "$kind" = "server" ] && echo server || echo client)-consul-0.pem \
    nomad-consul-cert.pem
mv dc1-$([ "$kind" = "server" ] && echo server || echo client)-consul-0-key.pem \
    nomad-consul-key.pem

if [[ "${DONT_MOVE:-"0"}" == "0" ]]; then
    rsync --rsync-path="sudo rsync" --remove-source-files --chown=root:root \
        nomad-consul-cert.pem nomad-consul-key.pem \
        mathm@ares.betasektionen.se:/var/lib/consul-certs/
fi
