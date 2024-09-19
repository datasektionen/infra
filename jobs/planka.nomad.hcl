variable "domain_name" {
  type    = string
  default = "planka.datasektionen.se"
}

variable "version" {
  type    = string
  default = "1.24.3"
}

job "planka" {
  group "planka" {
    network {
      port "http" {
        to = 1337
      }
    }

    service {
      name     = "planka"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.planka.rule=Host(`${var.domain_name}`)",
        "traefik.http.routers.planka.tls.certresolver=default",
      ]
    }

    volume "avatars" {
      type = "host"
      source = "planka/avatars"
    }

    volume "backgrounds" {
      type = "host"
      source = "planka/backgrounds"
    }

    volume "attachments" {
      type = "host"
      source = "planka/attachments"
    }

    task "planka" {
      driver = "docker"

      template {
        data = <<EOH
BASE_URL=https://${var.domain_name}
{{ with nomadVar "nomad/jobs/planka" }}
DATABASE_URL=postgres://planka:{{ .database_password }}@postgres.dsekt.internal:5432/planka
SECRET_KEY={{ .secret_key }}
DEFAULT_ADMIN_PASSWORD={{ .admin_password }}
OIDC_CLIENT_SECRET={{ .oidc_secret }}
{{ end }}
TRUST_PROXY=1

DEFAULT_ADMIN_EMAIL=d-sys@datasektionen.se
DEFAULT_ADMIN_NAME=Systemansvarig
DEFAULT_ADMIN_USERNAME=d-sys

OIDC_ISSUER=https://logout.datasektionen.se/op
OIDC_CLIENT_ID=mIioO0RJzRibAjY43Z3vG2eQ83Lzrz1EkNl_7-GVXbI=
# OIDC_ID_TOKEN_SIGNED_RESPONSE_ALG=ES256
# OIDC_USERINFO_SIGNED_RESPONSE_ALG=ES256
EOH
        destination = "local/.env"
        env = true
      }

      config {
        image = "ghcr.io/plankanban/planka:${var.version}"
        ports = ["http"]
      }

      volume_mount {
        volume = "avatars"
        destination = "/app/public/user-avatars"
      }

      volume_mount {
        volume = "backgrounds"
        destination = "/app/public/project-background-images"
      }

      volume_mount {
        volume = "attachments"
        destination = "/app/private"
      }

      resources {
        memory = 256
      }
    }
  }
}
