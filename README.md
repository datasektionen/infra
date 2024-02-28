## Installing on a new server

Make sure the server exists and that you can ssh to it as root with an ssh key

Install nixos on it with:
```sh
nix develop # unless you've got direnv
nixos-anywhere --flake .#$HOST_NAME root@$IP_ADDRESS
```

Delete entry from (local) known hosts, since the host key now has changed

Now you should be able to SSH to the server with any user from the nixos config

## Update the configuration on an existing server

```sh
NIX_SSHOPTS="-o RequestTTY=force" nixos-rebuild --flake .#$HOST_NAME --target-host $USER_NAME@$IP_ADDRESS --use-remote-sudo switch
```
