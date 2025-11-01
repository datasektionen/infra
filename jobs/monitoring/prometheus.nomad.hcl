job "prometheus" {
  type = "service"

  group "prometheus" {
    count = 1

    network {
      port "http" {}
    }

    volume "data" {
      type = "host"
      source = "prometheus/data"
    }

    task "prometheus" {
      driver = "docker"

      resources {
        cpu    = 60
        memory = 100
      }

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

      volume_mount {
        volume = "data"
        destination = "/prometheus"
      }

      template {
        data        = <<EOF
{{ with nomadVar "nomad/jobs/prometheus" }}
global:
  scrape_interval: 30s

# TODO: Also scrape node metrics
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
      # We only scrape targets with "prometheus.scrape=true" label
      - source_labels: [__meta_nomad_tags]
        regex: .*prometheus\.scrape=true.*
        action: keep
      # We cruedly extract the address from the traefik label and use it as the target.
      # We need to do this since the address itself is not directly accessable, but only
      # through the traefik router.
      #
      # This means that any service you will want to scrape metrics from also needs to have
      # a traefik router for it.
      - source_labels: [__meta_nomad_tags]
        regex: .*traefik\.http\.routers\.[^\.]+\.rule=Host\(`([^`]+)`\).*
        target_label: __address__
        replacement: $1:80
      # TODO: Use fields in a good consistent way for the labels
{{ end }}
EOF
        destination = "local/prometheus.yml"
      }

      template {
        data        = file("./files/nomad-agent-ca.pem")
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
