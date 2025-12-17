variable "domain_name" {
  type = string
  default = "n8n.datasektionen.se"
}

job "n8n" {
  namespace = "default"

  group "n8n" {
    network {
      port "http" {}
    }

    service {
      name = "n8n"
      port = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.n8n.rule=Host(`${var.domain_name}`)",
        "traefik.http.routers.n8n.tls.certresolver=default"
      ]
    }

    ephemeral_disk {
      size = 300 # MB for temporary files
    }

    task "n8n" {
      driver = "docker"

      config {
        image = "n8nio/n8n:1.120.4"
        ports = ["http"]
      }

      template {
        data = <<EOF
{{ with nomadVar "nomad/jobs/n8n" }}
N8N_ENCRYPTION_KEY={{ .encryption_key }}
DB_POSTGRESDB_PASSWORD={{ .db_password }}
N8N_SMTP_USER={{ .smtp_username }}
N8N_SMTP_PASS={{ .smtp_password }}
{{ end }}

# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres.dsekt.internal
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n

# Basic Configuration
N8N_PORT={{ env "NOMAD_PORT_http" }}
N8N_PROTOCOL="https"
N8N_HOST="${var.domain_name}"
WEBHOOK_URL="https://${var.domain_name}/"

# User Management & Security
N8N_USER_MANAGEMENT_DISABLED="false"
N8N_EMAIL_MODE="smtp"

# Performance Settings
N8N_CONCURRENCY_PRODUCTION_LIMIT="5"
EXECUTIONS_DATA_MAX_AGE="336" # 14 days in hours
EXECUTIONS_DATA_PRUNE="true"

# Development Settings
N8N_LOG_LEVEL="info"
N8N_VERSION_NOTIFICATIONS_ENABLED="true"
TZ="Europe/Stockholm"

# Disable diagnostics for privacy
N8N_DIAGNOSTICS_ENABLED="false"

# currently not using smtp
N8N_EMAIL_MODE=smtp
N8N_SMTP_HOST=email-smtp.eu-west-1.amazonaws.com
N8N_SMTP_PORT=587
N8N_SMTP_SENDER="n8n <noreply-n8n@datasektionen.se>"
N8N_SMTP_SSL=false
EOF
        destination = "local/.env"
        env = true
      }

      resources {
        cpu    = 500  # MHz
        memory = 1024 # MB
      }
    }
  }
}
