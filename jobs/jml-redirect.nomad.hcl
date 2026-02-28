job "jml-redirect" {
  namespace = "jml"
  type      = "service"

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
        "traefik.http.routers.jml-redirect.rule=Host(`jml.${base_domain}`)",
        "traefik.http.routers.jml-redirect.tls.certresolver=default",
        "traefik.http.routers.jml-redirect.middlewares=redirect-to-anmal",
        # slightly wrong because base_domain contains an unescaped dot, but ehh ¯\_(ツ)_/¯
        "traefik.http.middlewares.redirect-to-anmal.redirectregex.regex=https?://jml\\.${base_domain}/(.*)",
        "traefik.http.middlewares.redirect-to-anmal.redirectregex.replacement=https://anmal.${base_domain}/$$${1}",
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
