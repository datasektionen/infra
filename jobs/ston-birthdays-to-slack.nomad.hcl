job "ston-birthdays-to-slack" {
  namespace = "default"
  type = "batch"

  periodic {
    cron             = "0 0 9 * * * *" # every day at 9 AM
    time_zone        = "Europe/Stockholm"
    prohibit_overlap = true
  }

  group "ston-birthdays-to-slack" {
    task "call-ston-birthdays-endpoint" {
      driver = "docker" # cannot use exec because no nix-store in chroot = no bash

      template {
        data        = <<ENV
{{ with nomadVar "nomad/jobs/ston-birthdays-to-slack" }}
# note that token changes on login, so it should be for a user who doesn't
# ever login
STON_API_TOKEN="{{ .ston_api_token }}"
{{ end }}
ENV
        destination = "local/.env"
        env         = true
      }

      template {
        data        = <<SHELL
#!/bin/sh
set -eu

STON_BASE_URL="https://ston.datasektionen.se"
STON_ENDPOINT="$STON_BASE_URL/api/birthdays"

wget -O- --header "Authorization: Bearer $STON_API_TOKEN" "$STON_ENDPOINT"
SHELL
        destination = "local/call-ston-birthdays-endpoint.sh"
        perms       = "500" # r-x------
      }

      config {
        image   = "alpine:3.21"
        command = "./local/call-ston-birthdays-endpoint.sh"
      }
    }
  }
}
