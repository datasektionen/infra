job "keycloak" {
  group "keycloak" {
    network {
      mode = "bridge"

      port "http" {
        static = 8080
      }
    }

    service {
      name = "keycloak"
      port = "http"

      # tags = [
      #   "traefik.enable=true",
      #   "traefik.http.routers.http.rule=PathPrefix(`/count`)",
      # ]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "postgresql"
              local_bind_port = 5432
            }
          }
        }
      }
    }

    task "keycloak" {
      driver = "docker"

      template {
        data = <<EOH
DATABASE_URL=postgresql://{{ env "NOMAD_UPSTREAM_ADDR_postgres" }}/...
# Database

# The database vendor.
db=postgres

# The username of the database user.
db-username=keycloak

# The password of the database user.
db-password={{ with nomadVar "nomad/jobs/keycloak" }}{{ .database_password }}{{ end }}

# The full database JDBC URL. If not provided, a default URL is set based on the selected database vendor.
#db-url=jdbc:postgresql://{{ env "NOMAD_UPSTREAM_ADDR_postgres" }}/keycloak

# Observability

# If the server should expose healthcheck endpoints.
#health-enabled=true

# If the server should expose metrics endpoints.
#metrics-enabled=true

# HTTP

http-enabled=true
http-port={{ env "NOMAD_PORT_http" }}
# proxy-headers=xforwarded

# Hostname for the Keycloak server.
hostname-url=http://ares.betasektionen.se:8080
EOH
        destination = "local/keycloak.conf"
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
        cpu = 1000
        memory = 1024
      }
    }
  }
}
