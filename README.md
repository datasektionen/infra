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

## Nomad

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
