# Docker Multi-Platform Builds

Docker can build a single image for multiple architectures using [`docker-buildx`][buildx]. We use that here to build
a single Docker image for both `x86_64`/`amd64` and `arm64`/`aarch64`.

## Setup

[Install Docker Buildx][buildx-install], which is a CLI utility, and then run `docker buildx install` to have Docker use
`buildx` for all `build` commands. This will alias `docker-build` to `docker-buildx`.



 [buildx]: https://www.docker.com/blog/how-to-rapidly-build-multi-architecture-images-with-buildx/
 [buildx-install]: https://docs.docker.com/build/buildx/install/