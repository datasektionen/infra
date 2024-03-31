#!/bin/sh

set -eou pipefail

host="$1"
user="$2"

[ -f "dc1-server-consul-0.pem" ] && echo "Found existing cert. Remove or rename it first!" && exit 1

[ -f "consul-agent-ca-key.pem" ] || age -d -i "$AGE_IDENTITY" \
    -o "consul-agent-ca-key.pem" "secrets/consul-agent-ca-key.pem.age"

age -d -i "$AGE_IDENTITY" "secrets/consul-agent-ca-key.pem.age" | consul tls cert create \
    -ca=./files/consul-agent-ca.pem -key=/dev/stdin \
    -additional-dnsname="$host.betasektionen.se" \
    -node="$host" \
    -server

scp dc1-server-consul-0.pem dc1-server-consul-0-key.pem \
    "$user@$host.betasektionen.se":/tmp/

rm dc1-server-consul-0.pem dc1-server-consul-0-key.pem

ssh "$user@$host.betasektionen.se" sudo rsync \
    --remove-source-files --chown=consul:consul \
    /tmp/dc1-server-consul-0.pem /tmp/dc1-server-consul-0-key.pem \
    /var/lib/consul-certs/
