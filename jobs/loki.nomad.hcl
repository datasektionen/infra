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
      port "loki" {
        to = 3100
      }
    }

    task "loki" {
      driver = "docker"
      config {
        image = "grafana/loki:2.9.15"
        args = [
          "-config.file",
          "local/loki/local-config.yaml",
        ]
        ports = ["loki"]
      }

      template {
        data        = <<EOH
auth_enabled: false
server:
  http_listen_port: 3100
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
  max_transfer_retries: 0     # Chunk transfers disabled
schema_config:
  configs:
    - from: 2025-09-13
      store: tsdb
      object_store: s3
      schema: v13
      index:
        prefix: index_
        period: 24h
storage_config:
  tsdb_shipper:
    active_index_directory: /loki/tsdb-shipper-active
    cache_location: /loki/tsdb-shipper-cache
    shared_store: s3
  s3:
    bucketnames: dsekt-loki
    endpoint: https://s3.eu-north-1.amazonaws.com
    access_key_id: todo!
    secret_access_key: todo!
    insecure: false
compactor:
  working_directory: /tmp/loki/tsdb-shipper-compactor
  shared_store: s3
limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
chunk_store_config:
  max_look_back_period: 0s
table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
EOH
        destination = "local/loki/local-config.yaml"
      }

      resources {
        cpu    = 256
        memory = 256
      }
      service {
        name = "loki"
        port = "loki"

        check {
          name     = "Loki healthcheck"
          port     = "loki"
          type     = "http"
          path     = "/ready"
          interval = "20s"
          timeout  = "5s"
          check_restart {
            limit           = 3
            grace           = "60s"
            ignore_warnings = false
          }
        }

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.loki.rule=Host(`loki.nomad.dsekt.internal`)",
          "traefik.http.routers.loki.entrypoints=web-internal"
        ]
      }
    }
  }
}
