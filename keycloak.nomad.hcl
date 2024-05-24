job "keycloak" {
  group "keycloak" {
    network {
      port "http" { }
    }

    service {
      name = "keycloak"
      port = "http"
      provider = "nomad"

      tags = [
        "traefik-external.enable=true",
        "traefik-external.http.routers.keycloak.rule=Host(`keycloak.datasektionen.se`)",
        "traefik-external.http.routers.keycloak.entrypoints=websecure",
        "traefik-external.http.routers.keycloak.tls.certresolver=default",
      ]
    }

    task "keycloak" {
      driver = "docker"

      template {
        data = <<EOH
# Database

db=postgres
db-username=keycloak
db-password={{ with nomadVar "nomad/jobs/keycloak" }}{{ .database_password }}{{ end }}
db-url=jdbc:postgresql://postgres.dsekt.internal/keycloak

# Observability

# If the server should expose healthcheck endpoints.
#health-enabled=true

# If the server should expose metrics endpoints.
#metrics-enabled=true

# HTTP

http-enabled=true
http-port={{ env "NOMAD_PORT_http" }}
proxy-headers=xforwarded
hostname-url=https://keycloak.datasektionen.se
EOH
        destination = "local/keycloak.conf"
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/keycloak" }}
KEYCLOAK_ADMIN={{ .admin_username }}
KEYCLOAK_ADMIN_PASSWORD={{ .admin_password }}
{{ end }}
EOH
        destination = "local/.env"
        env = true
      }

      config {
        image = "quay.io/keycloak/keycloak:24.0"
        ports = ["http"]
        volumes = [
          "local/keycloak.conf:/opt/keycloak/conf/keycloak.conf"
        ]
        args = ["start"]
      }

      resources {
        memory = 1024
      }
    }
  }
}
