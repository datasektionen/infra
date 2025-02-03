variable "domain_name" {
  type    = string
  default = "planka.datasektionen.se"
}

job "planka" {
  type = "service"

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

    volume "user-avatars" {
      type   = "host"
      source = "planka/user-avatars"
    }

    volume "project-background-images" {
      type   = "host"
      source = "planka/project-background-images"
    }

    volume "attachments" {
      type   = "host"
      source = "planka/attachments"
    }

    task "planka" {
      driver = "docker"

      template {
        data        = <<ENV
TZ=Europe/Stockholm
BASE_URL=https://${var.domain_name}
OIDC_ISSUER=https://sso.datasektionen.se/op
OIDC_USERNAME_ATTRIBUTE=sub
{{ with nomadVar "nomad/jobs/planka" }}
OIDC_CLIENT_ID={{ .oidc_client_id }}
OIDC_CLIENT_SECRET={{ .oidc_client_secret }}
DATABASE_URL=postgres://planka:{{ .database_password }}@postgres.dsekt.internal:5432/planka
SECRET_KEY={{ .secret_key }}
DEFAULT_ADMIN_PASSWORD={{ .admin_password }}
{{ end }}
DEFAULT_ADMIN_EMAIL=d-sys@datasektionen.se
DEFAULT_ADMIN_NAME=Systemansvarig
DEFAULT_ADMIN_USERNAME=admin
ENV
        destination = "local/.env"
        env         = true
      }

      config {
        image = "ghcr.io/plankanban/planka:1.24.4"
        ports = ["http"]
      }

      volume_mount {
        volume      = "user-avatars"
        destination = "/app/public/user-avatars"
      }

      volume_mount {
        volume      = "project-background-images"
        destination = "/app/public/project-background-images"
      }

      volume_mount {
        volume      = "attachments"
        destination = "/app/private/attachments"
      }

      resources {
        memory = 512
        cpu    = 150
      }
    }
  }
}
