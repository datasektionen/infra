job "loki" {
  type = "service"

  update {
    max_parallel      = 1
    health_check      = "checks"
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    progress_deadline = "5m"
  }

  group "loki" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      port "http" {}
    }

    task "loki" {
      driver = "docker"
      config {
        image = "grafana/loki:3.5.7"
        args = [
          "-config.file",
          "local/loki/local-config.yaml",
        ]
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 200
      }

      template {
        data        = <<EOH
common:
  path_prefix: /loki
auth_enabled: false
server:
  http_listen_port: {{ env "NOMAD_PORT_http" }}
ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h
  # All chunks will be flushed when they hit this age, default is 1h
  max_chunk_age: 1h
  # Loki will attempt to build chunks up to 1.5MB, flushing if chunk_idle_period or max_chunk_age is reached first
  chunk_target_size: 1048576
  # Must be greater than index read cache TTL if using an index cache (Default index read cache TTL is 5m)
  chunk_retain_period: 30s
schema_config:
  configs:
    - from: 2025-09-13
      store: tsdb
      object_store: s3
      schema: v13
      index:
        prefix: index_
        period: 24h
{{ with nomadVar "nomad/jobs/loki" }}
storage_config:
  tsdb_shipper:
    active_index_directory: /loki/tsdb-shipper-active
    cache_location: /loki/tsdb-shipper-cache
  aws:
    bucketnames: dsekt-loki
    endpoint: https://s3.eu-north-1.amazonaws.com
    access_key_id: {{ .aws_access_key_id }}
    secret_access_key: {{ .aws_secret_access_key }}
    insecure: false
    region: eu-north-1
{{ end }}
compactor:
  working_directory: /tmp/loki/tsdb-shipper-compactor
limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  volume_enabled: true
  retention_period: "720h" # 30 days
  max_query_lookback: "720h" # 30 days
table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
EOH
        destination = "local/loki/local-config.yaml"
      }

      service {
        name = "loki"
        port = "http"
        provider = "nomad"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.loki.rule=Host(`loki.nomad.dsekt.internal`)",
          "traefik.http.routers.loki.entrypoints=web-internal"
        ]
      }
    }
  }
}
