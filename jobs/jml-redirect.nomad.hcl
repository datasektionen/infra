job "jml-redirect" {
  type = "service"

  group "jml-redirect" {
    network {
      port "http" { }
    }

    service {
      name     = "jml-redirect"
      port     = "http"
      provider = "nomad"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.jml-redirect.rule=Host(`jml.datasektionen.se`)",
        "traefik.http.routers.jml-redirect.tls.certresolver=default",
        "traefik.http.routers.jml-redirect.middlewares=redirect-to-anmal",
        "traefik.http.middlewares.redirect-to-anmal.redirectregex.regex=https?://jml\\.datasektionen\\.se/(.*)",
        "traefik.http.middlewares.redirect-to-anmal.redirectregex.replacement=https://anmal.datasektionen.se/$${1}",
      ]
    }

    task "jml-redirect" {
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
