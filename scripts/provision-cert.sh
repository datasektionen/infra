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

[ -f "dc1-server-consul-0.pem" ] && echo "Found existing cert. Remove or rename it first!" && exit 1
[ -f "dc1-client-consul-0.pem" ] && echo "Found existing cert. Remove or rename it first!" && exit 1

[ -f "consul-agent-ca-key.pem" ] || age -d -i "$AGE_IDENTITY" \
    -o "consul-agent-ca-key.pem" "secrets/consul-agent-ca-key.pem.age"

consul tls cert create \
    -ca=./files/consul-agent-ca.pem -key=./consul-agent-ca-key.pem \
    -additional-dnsname="$host.betasektionen.se" \
    -additional-dnsname=$([ "$kind" = "server" ] && echo "server.global.nomad" || eho "client.global.nomad") \
    $([ "$kind" = "server" ] && echo -node="$host" -server || echo -client)

mv dc1-$([ "$kind" = "server" ] && echo server || echo client)-consul-0.pem     dc1-consul-0.pem
mv dc1-$([ "$kind" = "server" ] && echo server || echo client)-consul-0-key.pem dc1-consul-0-key.pem

scp dc1-consul-0.pem dc1-consul-0-key.pem \
    "$SSH_USER@$host.betasektionen.se":/tmp/

rm dc1-consul-0.pem dc1-consul-0-key.pem

ssh "$SSH_USER@$host.betasektionen.se" sudo rsync \
    --remove-source-files --chown=consul:consul \
    /tmp/dc1-consul-0.pem /tmp/dc1-consul-0-key.pem \
    /var/lib/consul-certs/
