## State

State is stored in the S3 bucket `dsekt-tf-state`. It was created with the following settings:
- region: eu-north-1
- object ownership: acls disabled
- block all public access
- bucket versioning: enable
- default encryption:
  - encryption type: server-side encryption with amazon s3 managed keys (sse-s3)
  - bucket key: enable
- advanced settings: object lock: disable

State locking is done with the DynamoDB table `tf-lock`. It was created with the following settings:
- partition key: `LockID`, type `String`
- sort key: (blank)
- table settings: customize
- table class: DynamoDB standard
- read/write capacity settings: on-demand
- encryption key management: owned by Amazon DynamoDB

To access this state (and locking), you need valid credentials to do so. These are sourced the same way as the in aws cli, so either environment variables (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) or in `~/.aws/credentials`. The required permissions are specified [in the docs](https://opentofu.org/docs/language/settings/backends/s3/).

## Secrets

Secrets that need to be deployed are handled with [agenix](https://github.com/ryantm/agenix).

They are stored in `secrets/<name>.age` and encrypted with the ssh/age keys specified in `secrets/secrets.nix`.

## ACLs

After starting up the nomad cluster, it's ACL must be bootstrapped with:
```sh
nomad acl bootstrap
```
This will print out the `Secret ID` of a token with all permissions. This should be saved somewhere safe, like a `.env`-file. There is no real need to save online, since the acl system can be [re-bootstrapped](https://developer.hashicorp.com/nomad/tutorials/access-control/access-control-bootstrap#re-bootstrap-acl-system) if the token is lost.

## Certificates

Nomad needs certificates to communicate within a cluster securely. There is a CA created by the nomad cli located at `files/nomad-agent-ca.pem` with the key at `secrets/nomad-agent-ca-key.pem.age` (encrypted). When a server is created anew by OpenTofu, a certificate for it will automatically be created and moved to the correct place, but it will need to be renewed after some time, which can be done by running:
```sh
./scripts/provision-cert.sh <"client"|"server"> <hostname>
```
