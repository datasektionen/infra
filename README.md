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

## Starting the cluster from nothing

Some resources in the OpenTofu configuration are required to start the nomad cluster and some require the nomad cluster to be running but there is no way (?) to bootstrap nomad's ACL system in OpenTofu, so this has to be split up in multiple steps.

First, run
```sh
tofu apply -target='random_pet.stage1_nomad_cluster'
```

Then, the cluster should be ready, so bootstrap it's ACL system with:
```sh
nomad acl bootstrap
```
This will print out the `Secret ID` of a token with all permissions. This should be saved somewhere safe, like a `.env`-file. There is no real need to save online, since the acl system can be [re-bootstrapped](https://developer.hashicorp.com/nomad/tutorials/access-control/access-control-bootstrap#re-bootstrap-acl-system) if the token is lost.

Lastly, apply the rest of the OpenTofu configuration:
```sh
tofu apply
```

But this will override `secrets/nomad-traefik-acl-token.env.age`, so you must now run the last command again :^)

## Certificates

Nomad needs certificates to communicate within a cluster securely. There is a CA created by the nomad cli located at `files/nomad-agent-ca.pem` with the key at `secrets/nomad-agent-ca-key.pem.age` (encrypted). When a server is created anew by OpenTofu, a certificate for it will automatically be created and moved to the correct place, but it will need to be renewed after some time, which can be done by running:
```sh
./scripts/provision-cert.sh <"client"|"server"> <hostname>
```

## Authentication

### AWS

Either set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables or put something like:
```ini
[default]
aws_access_key_id = ...
aws_secret_access_key = ...
```
in `~/.aws/credentials`.

### Cloudflare

Set the `cloudflare_api_token` tf variable, e.g. by setting the `TF_VAR_cloudflare_api_token` environment variable.

To create a token
- Go to `https://dash.cloudflare.com/profile/api-tokens`;
- click *Create Token*;
- pick the *Create Additional Tokens* template;
- at the top, change it's name to (something like) "$USER Admin Token";
- under permissions, add *Zone* -> *DNS* -> *Edit*; and
- set the TTL to a reasonable date.

### Hetzner Cloud

Set the `hcloud_token` tf variable, e.g. by setting the `TF_VAR_hcloud_token` environment variable.

### GitHub

Authenticate with the github cli using:

```sh
gh auth login -s admin:org
```

When asked about preferred protocol for git operations, pick any and then pick `no` or `Skip` on the following option. (And then wonder how they managed to make such a horrible cli tool).

The `admin:org` scope is needed to set github actions secrets and variables.
