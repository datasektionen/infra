variable "domain_name" {
  type    = string
  default = "apollo.metaspexet.se"
}

job "apollo" {
  type = "service"
  namespace = "metaspexet"

  group "apollo" {
    network {
      port "http" { }
      port "api" { }
    }

    service {
      name     = "apollo-web"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.apollo.rule=Host(`${var.domain_name}`)",
        "traefik.http.routers.apollo.tls.certresolver=default",
      ]
    }

    service {
      name     = "apollo-api"
      port     = "api"
      provider = "nomad"
    }

    volume "data" {
      type = "host"
      source = "apollo/data"
    }

    task "apollo-web" {
      driver = "docker"

      template {
        data        = <<ENV
{{ with nomadVar "nomad/jobs/apollo" }}
{{ end }}
WEB_PORT={{ env "NOMAD_PORT_http" }}
{{ range nomadService "apollo-api" }}
API_PORT={{ .Port }}
API_UPSTREAM_ORIGIN=http://{{ .Address }}:{{ .Port }}
{{ end }}
ENV
        destination = "local/.env"
        env         = true
      }

      config {
        image = "ghcr.io/lindeb2/apollo-web:latest"
        ports = ["http"]
      }

      resources {
        memory = 20
        cpu    = 150
      }
    }

    task "apollo-api" {
      driver = "docker"

      template {
        data        = <<ENV
{{ with nomadVar "nomad/jobs/apollo" }}
DATABASE_URL=postgres://apollo:{{ .db_password }}@postgres.dsekt.internal:5432/apollo
JWT_ACCESS_SECRET={{ .jwt_access_secret }}
JWT_REFRESH_SECRET={{ .jwt_refresh_secret }}
OIDC_CLIENT_SECRET={{ .oidc_secret }}
{{ end }}
API_PORT={{ env "NOMAD_PORT_api" }}
OIDC_ISSUER=https://sso.datasektionen.se/op
OIDC_CLIENT_ID=apollo
OIDC_REDIRECT_URI=https://apollo.metaspexet.se/api/auth/oidc/callback
OIDC_SCOPES="openid profile email"
OIDC_USE_PKCE=false
ABSOLUTE_MEDIA_ROOT=/data
COOKIE_SECURE=true
ENV
        destination = "local/.env"
        env         = true
      }

      config {
        image = "ghcr.io/lindeb2/apollo-api:latest"
        ports = ["api"]
      }

      volume_mount {
        volume = "data"
        destination = "/data"
      }

      resources {
        memory = 300
        cpu = 150
      }
    }
  }
}
