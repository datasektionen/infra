variable "domain_name" {
  type    = string
  default = "mattermost.datasektionen.se"
}

job "mattermost" {
  namespace = "mattermost"

  group "mattermost" {
    network {
      port "http" { }
      port "calls" {
        to = 8443
      }
    }

    service {
      name     = "mattermost"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.mattermost.rule=Host(`${var.domain_name}`)",
        "traefik.http.routers.mattermost.tls.certresolver=default",
      ]
    }

    service {
      name     = "mattermost-calls"
      port     = "calls"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.tcp.routers.calls-tcp.rule=ClientIP(`0.0.0.0/0`)",
        "traefik.tcp.routers.calls-tcp.entrypoints=mattermost-calls-tcp",
        "traefik.udp.routers.calls-udp.entrypoints=mattermost-calls-udp",
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
DOMAIN=${var.domain_name}
MM_SQLSETTINGS_DRIVERNAME=postgres
{{ with nomadVar "nomad/jobs/mattermost" }}
MM_SQLSETTINGS_DATASOURCE=postgres://mattermost:{{ .database_password }}@postgres.dsekt.internal:5432/mattermost?sslmode=disable&connect_timeout=10
MM_EMAILSETTINGS_SMTPPASSWORD={{ .smtp_password }}
MM_EMAILSETTINGS_SMTPUSERNAME={{ .smtp_username }}
{{ end }}
MM_SERVICESETTINGS_SITEURL=https://${var.domain_name}
MM_SERVICESETTINGS_LISTENADDRESS=:{{ env "NOMAD_PORT_http" }}
MM_EMAILSETTINGS_SMTPSERVER=email-smtp.eu-north-1.amazonaws.com
MM_EMAILSETTINGS_SMTPPORT=2465
MM_EMAILSETTINGS_CONNECTIONSECURITY=TLS
MM_EMAILSETTINGS_ENABLESMTPAUTH=true
MM_EMAILSETTINGS_FEEDBACKEMAIL=mattermost@datasektionen.se
MM_EMAILSETTINGS_REPLYTOADDRESS=no-reply@datasektionen.se
EOH
        destination = "local/.env"
        env = true
      }

      config {
        image = "mattermost/mattermost-enterprise-edition:10.10.1"
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
        cpu    = 400
      }
    }
  }
}
