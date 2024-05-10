job "mattermost" {
  group "mattermost" {
    network {
      port "http" { }
      port "calls" {
        to = 8443
      }
    }

    service {
      name = "mattermost"
      port = "http"
      provider = "nomad"
      tags = [
        "traefik-external.enable=true",
        "traefik-external.http.routers.mattermost.rule=Host(`mattermost.ares.betasektionen.se`)",
        "traefik-external.http.routers.mattermost.entrypoints=websecure",
        "traefik-external.http.routers.mattermost.tls.certresolver=default",
      ]
    }

    service {
      name = "mattermost-calls"
      port = "calls"
      provider = "nomad"
      tags = [
        "traefik-external.enable=true",
        "traefik-external.tcp.routers.calls-tcp.entrypoints=mattermost-calls-tcp",
        "traefik-external.tcp.routers.calls-tcp.rule=ClientIP(`0.0.0.0/0`)",
        "traefik-external.udp.routers.calls-udp.entrypoints=mattermost-calls-udp",
      ]
    }

    volume "config" {
      type = "host"
      source = "mattermost/config"
    }

    volume "data" {
      type = "host"
      source = "mattermost/data"
    }

    volume "logs" {
      type = "host"
      source = "mattermost/logs"
    }

    volume "plugins" {
      type = "host"
      source = "mattermost/plugins"
    }

    volume "client/plugins" {
      type = "host"
      source = "mattermost/client/plugins"
    }

    volume "bleve-indexes" {
      type = "host"
      source = "mattermost/bleve-indexes"
    }

    task "mattermost" {
      driver = "docker"

      template {
        data = <<EOH
TZ=Europe/Stockholm
DOMAIN=mattermost.ares.betasektionen.se
MM_SQLSETTINGS_DRIVERNAME=postgres
{{ with nomadVar "nomad/jobs/mattermost" }}
MM_SQLSETTINGS_DATASOURCE=postgres://mattermost:{{ .database_password }}@postgres.dsekt.internal:5432/mattermost?sslmode=disable&connect_timeout=10
{{ end }}
MM_SERVICESETTINGS_SITEURL=https://mattermost.ares.betasektionen.se
MM_SERVICESETTINGS_LISTENADDRESS=:{{ env "NOMAD_PORT_http" }}
EOH
        destination = "local/.env"
        env = true
      }

      config {
        image = "mattermost/mattermost-enterprise-edition:9.8.0"
        ports = ["http", "calls"]
      }

      volume_mount {
        volume = "config"
        destination = "/mattermost/config"
      }

      volume_mount {
        volume = "data"
        destination = "/mattermost/data"
      }

      volume_mount {
        volume = "logs"
        destination = "/mattermost/logs"
      }

      volume_mount {
        volume = "plugins"
        destination = "/mattermost/plugins"
      }

      volume_mount {
        volume = "client/plugins"
        destination = "/mattermost/client/plugins"
      }

      volume_mount {
        volume = "bleve-indexes"
        destination = "/mattermost/bleve-indexes"
      }

      resources {
        memory = 2048
      }
    }
  }
}
