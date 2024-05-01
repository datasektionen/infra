job "alpine-test" {
  group "alpine-test" {
    network {
      mode = "bridge"

      port "http" {
        static = 80
      }
    }

    service {
      name = "alpine-test"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "postgresql"
              local_bind_port = 5432
            }
          }
        }
      }
    }

    task "alpine-test" {
      driver = "docker"

      config {
        image = "alpine:3.19"
        ports = ["http"]
        command = "tail"
        args = ["-f", "/dev/null"]
      }
    }
  }
}
