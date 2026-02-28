job "immich" {
  type = "service"

  group "immich" {
    network {
      port "http" { }
      port "redis" {
        to = 6379
      }
    }

    service {
      name     = "immich"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.immich.rule=Host(`${domain_name}`)",
        "traefik.http.routers.immich.tls.certresolver=default",
      ]
    }

    service {
      name     = "redis"
      provider = "nomad"
      port     = "redis"
    }

    volume "uploads" {
      type      = "host"
      source    = "immich/uploads"
    }

    task "immich-server" {
      driver = "docker"

      config {
        image = var.server_image
        ports = ["http"]
      }

      template {
        data = <<ENV
{{ with nomadVar "nomad/jobs/immich" }}
DB_HOSTNAME=postgres.dsekt.internal
DB_USERNAME=immich
DB_PASSWORD={{ .db_password }}
DB_DATABASE_NAME=immich

{{ range nomadService "redis" }}
REDIS_HOSTNAME={{ .Address }}
REDIS_PORT={{ .Port }}
{{ end }}

IMMICH_MACHINE_LEARNING_URL=http://localhost:3003
{{ end }}

IMMICH_PORT={{ env "NOMAD_PORT_http" }}
ENV
        destination = "local/.env"
        env         = true
      }

      volume_mount {
        volume      = "uploads"
        destination = "/data"
      }

      resources {
        memory = 1536
      }
    }

      task "redis" {
      driver = "docker"

      config {
        image = var.redis
        ports = ["redis"]
      }

      resources {
        memory = 64
      }
    }
  }
}

variable "server_image" {
  type    = string
  default = "ghcr.io/immich-app/immich-server:release"
}

variable "redis" {
  type    = string
  default = "valkey/valkey:latest"
}
