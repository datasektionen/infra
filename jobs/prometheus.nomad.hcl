job "prometheus" {
  type = "service"

  group "prometheus" {
    count = 1

    network {
      port "http" {}
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v3.6.0"
        ports = ["http"]
        args = [
          "--web.listen-address=0.0.0.0:${NOMAD_PORT_http}",
          "--config.file=/etc/prometheus/prometheus.yml"
        ]
        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
          "local/nomad-ca.pem:/etc/prometheus/nomad-ca.pem"
        ]
      }

      template {
        data        = <<EOF
{{ with nomadVar "nomad/jobs/prometheus" }}
global:
  scrape_interval: 30s

scrape_configs:
  - job_name: nomad
    # For some reason '*' namespace does not work
    # TODO: dynamically generate this for all namespaces
    nomad_sd_configs:
      - server: https://{{ env "attr.unique.hostname" }}.dsekt.internal:4646
        namespace: default
        authorization:
          type: Bearer
          credentials: {{ .nomad_token }}
        tls_config:
          ca_file: /etc/prometheus/nomad-ca.pem
      - server: https://{{ env "attr.unique.hostname" }}.dsekt.internal:4646
        namespace: metaspexet
        authorization:
          type: Bearer
          credentials: {{ .nomad_token }}
        tls_config:
          ca_file: /etc/prometheus/nomad-ca.pem
    relabel_configs:
      - source_labels: [__meta_nomad_tags]
        regex: .*prometheus\.scrape=true.*
        action: keep
      - source_labels: [__meta_nomad_tags]
        regex: .*traefik\.http\.routers\.[^\.]+\.rule=Host\(`([^`]+)`\).*
        target_label: __address__
        replacement: $1:80
{{ end }}
EOF
        destination = "local/prometheus.yml"
      }

      template {
        data        = file("../files/nomad-agent-ca.pem")
        destination = "local/nomad-ca.pem"
      }

      service {
        name     = "prometheus"
        port     = "http"
        provider = "nomad"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.prometheus.rule=Host(`prometheus.nomad.dsekt.internal`)",
          "traefik.http.routers.prometheus.entrypoints=web-internal"
        ]
      }
    }
  }
}
