## State

State is stored in the S3 bucket `dsekt-terraform-state`. It was created with the following settings:
- region: eu-north-1
- object ownership: acls disabled
- block all public access
- bucket versioning: enable
- default encryption:
  - encryption type: server-side encryption with amazon s3 managed keys (sse-s3)
  - bucket key: enable
- advanced settings: object lock: disable

State locking is done with the DynamoDB table `terraform-lock`. It was created with the following settings:
- partition key: `LockID`, type `String`
- sort key: (blank)
- table settings: customize
- table class: DynamoDB standard
- read/write capacity settings: on-demand
- encryption key management: owned by Amazon DynamoDB

To access this state (and locking), you need valid credentials to do so. These are sourced the same way as the in aws cli, so either environment variables (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) or in `~/.aws/credentials`. The required permissions are specified [in the docs](https://developer.hashicorp.com/terraform/language/settings/backends/s3).

## Secrets

Secrets that need to be deployed are handled with [agenix](https://github.com/ryantm/agenix).

They are stored in `secrets/<name>.age` and encrypted with the ssh/age keys specified in `secrets/secrets.nix`.

## ACLs

After starting up the consul cluster, it's ACL must be bootstrapped with:
```sh
consul acl bootstrap
```
This will print out the `SecretID` of a token with all permissions. This should be saved somewhere safe. (You can put in in the environment variable `CONSUL_HTTP_TOKEN`) to get permission to run the following `consul` commands.

Nomad agents need permission to talk to consul. They need a policy created like:
```sh
consul acl policy create -name "nomad-auto-join" -rules=- <<HCL
acl = "write"

agent_prefix "" {
    policy = "write"
}

event_prefix "" {
    policy = "write"
}

key_prefix "" {
    policy = "write"
}

node_prefix "" {
    policy = "write"
}

query_prefix "" {
    policy = "write"
}

service_prefix "" {
    policy = "write"
}
HCL
```

And a token can be created with (last line only needed if you want to reuse a saved secret):
```sh
consul acl token create \
  -description "Nomad auto-join token" -policy-name "nomad-auto-join" \
  -secret=$(age -i "$AGE_IDENTITY" -d secrets/nomad-consul-token.env.age | awk -F= '{print $2}')
```

Then Nomad's ACL also needs to be bootstrapped with:
```sh
nomad acl bootstrap
```

## Certificates

Both Consul and Nomad need certificates to communicate within a cluster securely. We have a CA created by the consul cli located at `files/consul-agent-ca.pem` with the key (encrypted) at `secrets/consul-agent-ca-key.pem.age`. You can create a certificate and key and move it to a server so that both consul and nomad can use it using:
```sh
./scripts/provision-cert.sh <"client"|"server"> <hostname>
```
