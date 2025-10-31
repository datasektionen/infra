# Infra(structure) 🛣️

Each server runs NixOS and is defined by the file called `hosts/$hostname.nix` and those that are VMs on Hetzner Cloud have their existence defined at the top of `hosts.tf`. They all live in the cloud project called "Informationsorganet".

They are all on the same private network with the network prefix `10.83.0.0/16`. (Chosen because obviously class A private networks must be better than class B and C and 1983 is the chapter's birthyear). It is defined within Hetzner, which means that `10.83.0.1` is reserved by them. The servers is then put in the `10.83.0.0/24` subnet, so that we can put other stuff in other `10.38.?.0/24` subnets, which we do with `10.83.1.0/24` which contains hosts that are bridged via the host _hades_ using wireguard.

Systems are ran by nomad and deployed by a job file in their own repository. Unfortunately, it's not possible to give someone access to interact with just some specific jobs, but rather with some specific namespaces. Jobs in different namespaces can however not talk with each other using Nomad's built-in networking. To let jobs talk with each other we use a traefik instance running on each nomad client node (those that run jobs). For connecting between jobs internally the hostname `<job name>.nomad.dsekt.internal` should be used as this will point to the current server's ip address in the private network where traefik will listen on port 80 and proxy the request to the job, no matter which namespace or host it's on.

We also host some third party websites in nomad (e.g. mattermost) and these have their job specs in this repository and are referenced in `nomad.tf`.

All servers run bind9, a DNS server. Within it, each host get the domain name `$hostname.dsekt.internal`. Additionally, services/programs running on a specific host (i.e. not in nomad) should get a CNAME record at `$name.dsekt.internal` pointing to its host.

A postgres(ql) instance is running on the host _ares_. It has regularly scheduled backups which are stored on S3.

Life would be easier if programs never needed persistent storage as a file system directory/file, but that's not always the case. One could probably invest some time in [CSI](https://github.com/hetznercloud/csi-driver/blob/main/docs/nomad/README.md) to store those in a Hetzner volume or something like that, but currently host volumes are used. They can be defined using the option `dsekt.nomad.volumes.host.<name>` in a host's NixOS config and then be referenced in a job spec. Note that this locks the job to that host and that the name must be globally unique.

Tokens for auth{enticating,orizing} deployments from GitHub actions are defined in `github.tf`. They are uploaded to GitHub automatically. There is also an organization wide variable for the URL which together with the token should be all that is needed to deploy jobs.

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

We make some values from tofu available in nix through some hackery, which you after cloning the repository need to set up using:

```sh
git config filter.bogus-generated.clean "echo '(generated file, will be updated by tofu)'"
git config filter.bogus-generated.smudge "echo 'throw \"This file will be generated when running tofu. Please do so before fiddling with nix.\"'"
```

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
Maybe the nomad systemd service has to be restarted after that but that should be all.

The current CA certificate will expire at 2029-04-30 17:24:25 UTC, so it will have to be replaced before then!

## Authentication required to run tofu

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

To create a token:
- Go to `https://dash.cloudflare.com/profile/api-tokens`;
- click *Create Token*;
- pick the *Create Additional Tokens* template;
- at the top, change its name to (something like) "$USER Admin Token";
- under permissions, add *Zone* -> *DNS* -> *Edit*; and
- set the TTL to a reasonable date.

### Hetzner Cloud

Set the `hcloud_token` tf variable, e.g. by setting the `TF_VAR_hcloud_token` environment variable.

To create a token:
- Go to `https://console.hetzner.cloud/projects`;
- pick *Informationsorganet*;
- in the sidebar, click *Security*;
- at the top, click *API tokens*;
- in the top right, click *Generate API token*; and
- under permissions, pick *Read & Write*.

### GitHub

Authenticate with the GitHub cli using:

```sh
gh auth login -s admin:org
```

When asked about preferred protocol for git operations, pick any and then pick `no` or `Skip` on the following option. (And then wonder how they managed to make such a horrible cli tool).

The `admin:org` scope is needed to set GitHub actions secrets and variables.

## Authenticating to Nomad

It is possible to authenticate to the nomad cluster using [sso](https://sso.datasektionen.se/). If you have permission to some namespace, either:
- type `nomad login`, log in to your account in the web browser that should've opened
- copy the value following `Secret ID =` and store it as an environment variable (e.g. `export NOMAD_TOKEN=...`). It will be valid for 12 hours.
- continue using the nomad cli or run `nomad ui -authenticate` to log in to the web ui
or:
- go to <https://nomad.datasektionen.se/ui/settings/tokens>
- click "Sign in with sso"
- log in to your account in the newly opened tab
- continue using the nomad web ui or copy the Secret ID and store in an env variable as described above

You will get read/write access to the namespaces described in the nomad group(s) you're added to in [pls](https://pls.datasektionen.se/).

Note however that only namespaces that are defined in `local.namespaces_for_humans` in `nomad.tf` can be given access to via pls.

## How-to-guide

The purpose of this section is to have one sub-section for every thing that an administrator of this repository may want to do with a short guide. If you do something that required some figuring out, it would probably be good to add a section here with what you figured out!

### Add auto-deployment to a new repository

- Add an entry in `locals.deploy-tokens.<namespace>` in `github.tf` for whatever namespace it should be in.
  - run `tofu apply`
- create an amazingly well-build Dockerfile in the repository
- copy a `job.nomad.hcl` from some other hopefully relatively similar system
  - switch out it's name (search and replace it)
  - change the domain name in the traefik config
  - modify everything else as needed
- copy <https://github.com/datasektionen/nomad-deploy/blob/master/deploy.example.yml> to `.github/workflows/deploy.yml` in the repository.
  - switch out the branch name if needed
- create the nomad variable that it needs using `nomad var put`
  - this should not be done through tofu since that requires some fippel and the job spec clearly states exactly which variables need to exist so it doesn't really provide any benefits
  - if one of them is a database password, connect to the database on ares (e.g. using `ssh -t ares sudo -u postgres psql`) and run `create user schmunguss password '<the-password-which-can-be-some-uuid>'; create database schmunguss owner schmunguss;`.
- deploy and enjoy 😎

### Add a namespace

- Add something like:
  ```terraform
  resource "nomad_namespace" "coolshit" {
    name        = "coolshit"
    description = "Cool shit"
  }
  ```
  to `nomad.tf` by the others
- add its name to `services.traefik.staticConfigOptions.providers.nomad.namespaces` in `/profiles/traefik.nix`
- run `tofu apply`

### Deploy some open source thing

Most such services have a docker compose file which can be used for deployment. These often configure everything, including reverse proxy and databases themselves. Using other nomad job specs as reference, convert the compose file to a nomad job spec. Of course, it should use our centralized database and register itself with our centralized traefik instance rather than creating such things as more containers. This requires that the program is published as a docker image in some public registry. Also add a `nomad_job` resource to `nomad.tf` so that `tofu apply` will run it.

It is also possible to fork the thing and create a job spec and deployment action in the repository, which I did with [mattfbacon/typst-bot](https://github.com/datasektionen/typst-bot) since it wasn't published as a docker image anywhere.
