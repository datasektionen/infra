job "djul-redirect" {
  type = "service"

  group "djul-redirect" {
    network {
      port "http" { }
    }

    service {
      name     = "djul-redirect"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.djul-redirect.rule=Host(`djul.se`)||Host(`www.djul.se`)||Host(`djul.datasektionen.se`)",
        "traefik.http.routers.djul-redirect.tls.certresolver=default",
        "traefik.http.routers.djul-redirect.middlewares=redirect-to-djul-discord,redirect-to-djul-base",
        "traefik.http.middlewares.redirect-to-djul-discord.redirectregex.regex=^https://(www[.])?djul[.]se/discord$",
        "traefik.http.middlewares.redirect-to-djul-discord.redirectregex.replacement=https://discord.gg/PsYrBC4a7z",
        "traefik.http.middlewares.redirect-to-djul-base.redirectregex.regex=^.*$",
        "traefik.http.middlewares.redirect-to-djul-base.redirectregex.replacement=https://djulkalendern.se/",
      ]
    }

    task "djul-redirect" {
      driver = "docker"

      config {
        image   = "alpine:3.20"
        command = "tail"
        args    = ["-f", "/dev/null"]
      }

      resources {
        memory = 10 # this job should take about 0.5MiB, but the minimum allowed to put here is 10
      }
    }
  }
}
