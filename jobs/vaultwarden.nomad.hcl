job "vault" {
  namespace = "vault"

  group "vault" {
    network {
      port "http" { }
    }

    service {
      name     = "vault"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.vault.rule=Host(`${domain_name}`)",
        "traefik.http.routers.vault.tls.certresolver=default",
      ]
    }

    volume "data" {
      type = "host"
      source = "vault/data"
    }

    task "vault" {
      driver = "docker"

      config {
        image = "vaultwarden/server:1.35.2-alpine"
        ports = ["http"]
      }

      template {
        data = <<EOF
DOMAIN=https://${domain_name}
ROCKET_PORT={{ env "NOMAD_PORT_http" }}
{{ with nomadVar "nomad/jobs/vault" }}
DATABASE_URL=postgres://vaultwarden:{{ .db_password }}@postgres.dsekt.internal:5432/vaultwarden?sslmode=disable&connect_timeout=10
SMTP_USERNAME={{ .smtp_username }}
SMTP_PASSWORD={{ .smtp_password }}
SSO_CLIENT_SECRET={{ .oidc_secret }}
{{ end }}
SMTP_HOST=email-smtp.eu-north-1.amazonaws.com
SMTP_PORT=587
SMTP_FROM=no-reply@datasektionen.se
SMTP_FROM_NAME="Datasektionen Vault"
INVITATION_ORG_NAME="Datasektionen Vault"
SIGNUPS_ALLOWED=false
SIGNUPS_VERIFY=true
SIGNUPS_DOMAINS_WHITELIST=datasektionen.se,kth.se
ORG_CREATION_USERS=d-sys@datasektionen.se
ORG_GROUPS_ENABLED=true
ADMIN_TOKEN=$argon2id$v=19$m=65540,t=3,p=4$Eq5XC4/9uPFrvVadxrAEBD3+cvaUjZaXWuJkxMAGiQQ$BDzKBz53KMb+e8hIaiCca42ZRak8RFW09qVCXjqgfPk
SSO_ENABLED=true
SSO_SIGNUPS_MATCH_EMAIL=true
SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION=false
SSO_AUTHORITY=https://sso.datasektionen.se/op
SSO_PKCE=false
SSO_CLIENT_ID=vaultwarden
SSO_CLIENT_CACHE_EXPIRATION=600
EOF
        destination = "local/.env"
        env = true
      }

      volume_mount {
        volume = "data"
        destination = "/data"
      }

      resources {
        memory = 128 // MB
      }
    }
  }
}
