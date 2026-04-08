variable "domain_name" {
  type    = string
  default = "manus.metaspexet.se"
}

job "dionysus" {
  type = "service"
  namespace = "metaspexet"

  group "dionysus" {
    network {
      port "http" {
        to = 8000
      }
    }

    service {
      name     = "dionysus"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.dionysus.rule=Host(`${var.domain_name}`)",
        "traefik.http.routers.dionysus.tls.certresolver=default",
      ]
    }

    task "dionysus" {
      driver = "docker"

      template {
    		data        = <<TOML
[oidc.providers.dsekt]
issuer = "https://sso.datasektionen.se/op"
scopes = ["openid", "profile", "email"]
TOML
        destination = "local/config.toml"
      }

      template {
        data        = <<ENV
{{ with nomadVar "nomad/jobs/dionysus" }}
DIONYSUS_CONFIG=/local/config.toml
DIONYSUS_DATABASE__URL=postgres://dionysus:{{ .db_password }}@postgres.dsekt.internal:5432/dionysus
DIONYSUS_OIDC__PROVIDERS__DSEKT__CLIENT_ID={{ .oidc_id }}
DIONYSUS_OIDC__PROVIDERS__DSEKT__CLIENT_SECRET={{ .oidc_secret }}
DIONYSUS_OIDC__BASE_EXTERNAL_ID=https://manus.metaspexet.se
{{ end }}
ENV
        destination = "local/.env"
        env         = true
      }

      config {
        image = "ghcr.io/frblo/dionysus:latest"
        ports = ["http"]
      }

      resources {
        memory = 64
        cpu    = 150
      }
    }
  }
}
