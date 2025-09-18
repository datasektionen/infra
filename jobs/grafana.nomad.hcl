job "grafana" {
  type = "service"

  group "metrics" {
    network {
      port "http" {}
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:latest"
        ports = ["http"]

        volumes = [
          "local/provisioning/loki.yml:/etc/grafana/provisioning/datasources/loki.yml",
        ]
      }

      env {
        GF_PATHS_CONFIG = "/local/config.ini"
        GF_PATHS_PROVISIONING = "/local/provisioning"
      }

      template {
               data = <<EOF
{{ with nomadVar "nomad/jobs/grafana" }}
[security]
admin_user = admin
admin_password = {{ .admin_password }}
{{ end }}
           EOF
               destination = "local/config.ini"
      }

      template {
        destination = "local/provisioning/datasources/prom.yml"
        data        = <<EOF
apiVersion: 1

datasources:
- name: Loki
  type: loki
  access: proxy
  url: http://loki.nomad.dsekt.internal:3100
  editable: false
EOF
      perms = "777"
      }

      service {
        name     = "grafana"
        port     = "http"
        provider = "nomad"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.grafana.rule=Host(`grafana.datasektionen.se`)",
          "traefik.http.routers.grafana.tls.certresolver=default"
        ]
      }
    }
  }
}
