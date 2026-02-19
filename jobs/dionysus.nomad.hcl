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
        data        = <<ENV
{{ with nomadVar "nomad/jobs/dionysus" }}
DATABASE_URL=postgres://dionysus:{{ .db_password }}@postgres.dsekt.internal:5432/dionysus
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
