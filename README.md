# Infra(structure) 🛣️

Each server runs NixOS and is defined by the file called `hosts/$hostname.nix` and those that are VMs on Hetzner Cloud have their existence defined at the top of `hosts.tf`. They all live in the cloud project called "Informationsorganet".

They are all on the same private network with the network prefix `10.83.0.0/16`. It is defined within Hetzner, which means that `10.83.0.1` is reserved by them.

Systems are ran by nomad and deployed by a job file in their own repository. Unfortunately, it's not possible to give someone access to interact with just some specific jobs, but rather with some specific namespaces. Jobs in different namespaces can however not talk with each other using Nomad's built-in networking. To let jobs talk with each other we use a traefik instance running on each nomad client node (those that run jobs). For connecting between jobs internally the hostname `<job name>.nomad.dsekt.internal` should be used as this will point to the current server's ip address in the private network where traefik will listen on port 80 and proxy the request to the job, no matter which namespace or host it's on.

We also host some third party websites in nomad (e.g. mattermost) and these have their job specs in this repository and are referenced in `nomad.tf`.

All servers run bind9, a DNS server. Within it, each host get the domain name `$hostname.dsekt.internal`. Additionally, services/programs running on a specific host (i.e. not in nomad) should get a CNAME record at `$name.dsekt.internal` pointing to its host.

A postgres(ql) instance is running on the host _ares_. It should have scheduled backups, but doesn't yet.

Life would be easier if programs never needed persistent storage as a file system directory/file, but that's not always the case. One could probably invest some time in [CSI](https://github.com/hetznercloud/csi-driver/blob/main/docs/nomad/README.md) to store those in a Hetzner volume or something like that, but currently host volumes are used. They can be defined using the option `services.nomad.settings.client.host_volume` in a host's NixOS config and then be referenced in a job spec. Note that this locks the job to that host.

Tokens for auth{enticating,orizing} deployments from GitHub actions are defined in `github.tf`. They are uploaded to GitHub automatically. To add a deployment action to a repository, add an entry there for the appropriate namespace and copy the deployment action and job spec from some other repository. (Would it maybe be nice to have a template/reference action and job spec?)

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

Then, the cluster should be ready, so bootstrap its ACL system with:
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
- at the top, change its name to (something like) "$USER Admin Token";
- under permissions, add *Zone* -> *DNS* -> *Edit*; and
- set the TTL to a reasonable date.

### Hetzner Cloud

Set the `hcloud_token` tf variable, e.g. by setting the `TF_VAR_hcloud_token` environment variable.

### GitHub

Authenticate with the GitHub cli using:

```sh
gh auth login -s admin:org
```

When asked about preferred protocol for git operations, pick any and then pick `no` or `Skip` on the following option. (And then wonder how they managed to make such a horrible cli tool).

The `admin:org` scope is needed to set GitHub actions secrets and variables.
