ARG RUST_VERSION=latest

# our first stage installs rust tools so that these are contained in their own stage
FROM rust:${RUST_VERSION} AS setup

# set our shell to bash and expose failures
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG RUST_SETUP_VERSION=2022-10-03
ARG TARGETPLATFORM=linux/amd64
ARG BUILDPLATFORM=linux/amd64

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# install build script library
COPY docker/build-scripts/lib/* ./docker/build-scripts/lib/

# stage 0, step 0: emit debugging information
COPY docker/build-scripts/stage-0-step-0-debug.sh ./docker/build-scripts/
RUN docker/build-scripts/stage-0-step-0-debug.sh

# stage 0, step 1: install system packages
COPY docker/build-scripts/stage-0-step-1-install-packages.sh ./docker/build-scripts/
RUN docker/build-scripts/stage-0-step-1-install-packages.sh

# install the musl toolchain for the target platform
# stage 0, step 2: install rustup target
COPY docker/build-scripts/stage-0-step-2-install-rustup-target.sh ./docker/build-scripts/
RUN docker/build-scripts/stage-0-step-2-install-rustup-target.sh

# install cargo utilities
ARG RUST_AUDITABLE_BINARY=true
ARG RUST_RUN_AUDIT=true

COPY docker/build-scripts/stage-0-step-3-install-cargo-tools.sh ./docker/build-scripts/
RUN docker/build-scripts/stage-0-step-3-install-cargo-tools.sh

FROM setup AS build

ENV APP_BIN_NAME=fuzzydatetime
ARG RUST_BUILD_VERSION=2022-10-03

# update utilities
COPY docker/build-scripts/stage-1-step-0-cargo-update.sh ./docker/build-scripts/
RUN docker/build-scripts/stage-1-step-0-cargo-update.sh

# copy files
COPY . /usr/src/app/

# run tests
ARG RUST_RUN_TESTS=true
RUN docker/build-scripts/stage-1-step-1-cargo-test.sh

# run audit
ARG RUST_RUN_AUDIT=true
RUN docker/build-scripts/stage-1-step-2-cargo-audit.sh

# build the static binary in release mode
ARG RUST_AUDITABLE_BINARY=true

RUN if [[ "$RUST_AUDITABLE_BINARY" == "true" ]] ; then \
        echo "*** including audit info in the binary as per RUST_AUDITABLE_BINARY=${RUST_AUDITABLE_BINARY} build arg..." >&2 ; \
        cargo auditable build --release ; \
    else \
        echo "*** excluding audit info from the binary as per RUST_AUDITABLE_BINARY=${RUST_AUDITABLE_BINARY} build arg..." >&2 ; \
        cargo build --release ; \
    fi

# build the static validation test
RUN cargo build --release --example static-test

# if RUST_STRIP_BINARY is set, strip the binary
ARG RUST_STRIP_BINARY=false

RUN if [[ "$RUST_STRIP_BINARY" == "true" ]] ; then \
      echo "*** stripping binary as per RUST_STRIP_BINARY=${RUST_STRIP_BINARY} build arg..." >&2 ; \
      strip target/release/${APP_BIN_NAME} ; \
    else \
      echo "*** not stripping binary as per RUST_STRIP_BINARY build arg..." >&2 ; \
    fi

RUN file target/release/examples/static-test

FROM alpine as final

# copy system requirements
COPY --from=build /usr/share/ca-certificates /usr/share/zoneinfo /usr/share/
COPY --from=build /etc/ca-certificates /etc/ssl /etc/

# copy built binaries
COPY --from=build /usr/src/app/target/release/fuzzydatetime /app
COPY --from=build /usr/src/app/target/release/examples/static-test /app-static-test

RUN apk add file
RUN ls -lh /
RUN file /app-static-test
RUN /app-static-test

# ensure that we have the runtime dependencies we need
RUN ["/app-static-test", "--self-destruct"]

ENTRYPOINT ["/app"]
