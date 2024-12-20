# To initialize the database, i had to run
# `tsx ./scripts/setup-db.ts` and `yarn database:migrate:prod`
# In the container with `nomad alloc exec ...`. The first command did complain
# a bunch about missing postgresql extensions but nothing else has complained
# about it so far...
# Making the container do this automatically does not work because then it
# wants to also CREATE THE DATABASE and is not happy about using an existing
# one, which might be the dumbest thing I've seen.

variable "image_tag" {
  type = string
  default = "v0.33"
}

variable "env" {
  type    = string
  default = <<EOF
PORT={{ env "NOMAD_PORT_http" }}
SERVER_URL=https://twenty.datasektionen.se
FRONT_BASE_URL=https://twenty.datasektionen.se

STORAGE_TYPE=s3
STORAGE_S3_REGION=eu-north-1
STORAGE_S3_NAME=dsekt-twenty
STORAGE_S3_ACCESS_KEY_ID=AKIATUCF4UAOU4JCDGND

CACHE_STORAGE_TYPE=memory
MESSAGE_QUEUE_TYPE=pg-boss

MESSAGING_PROVIDER_GMAIL_ENABLED=false
CALENDAR_PROVIDER_GOOGLE_ENABLED=false
IS_SIGN_UP_DISABLED=true

{{ with nomadVar "nomad/jobs/twenty" }}
PG_DATABASE_URL=postgres://twenty:{{ .database_password }}@postgres.dsekt.internal:5432/twenty
APP_SECRET={{ .app_secret }} # openssl rand -base64 32
STORAGE_S3_SECRET_ACCESS_KEY={{ .s3_secret_access_key }}
{{ end }}
EOF
}

job "twenty" {
  namespace = "twenty"

  group "twenty" {
    network {
      port "http" { }
    }

    service {
      name     = "twenty"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.twenty.rule=Host(`twenty.datasektionen.se`)",
        "traefik.http.routers.twenty.tls.certresolver=default",
      ]
    }

    task "server" {
      driver = "docker"

      config {
        image = "twentycrm/twenty:${var.image_tag}"
        ports = ["http"]
      }

      template {
        data        = var.env
        destination = "local/.env"
        env         = true
      }

      resources {
        memory = 1024 # OH MY GOD what bloat this is?
      }
    }

    task "worker" {
      driver = "docker"

      config {
        image   = "twentycrm/twenty:${var.image_tag}"
        command = "yarn"
        args    = ["worker:prod"]
      }

      template {
        data        = var.env
        destination = "local/.env"
        env         = true
      }

      resources {
        memory = 600 # oh my god what bloat this is?
      }

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }
    }
  }
}
