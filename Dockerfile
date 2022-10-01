FROM rust:latest as build

ENV APP_BIN_NAME=fuzzy-datetime
ENV MIN_BUILD_DATE=2022-09-30

ARG TARGETPLATFORM
ARG BUILDPLATFORM

# install system dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential libssl-dev libcurl4-openssl-dev musl musl-dev \
        musl-tools && \
    DEBIAN_FRONTEND=noninteractive apt-get update -y

RUN /usr/sbin/update-ca-certificates

RUN echo "$TARGETPLATFORM" "$BUILDPLATFORM"

# install the musl toolchain for amd64/aarch64
RUN RUSTUP_TARGET=`if echo "$TARGETPLATFORM" | grep -qP '^linux/amd64' ; then \
      echo '*** setting target to x86_64-unknown-linux-musl' >&2 ; \
      echo x86_64-unknown-linux-musl ; \
    elif echo "$TARGETPLATFORM" | grep -qP '^linux/arm64' ; then \
      echo '*** setting target to aarch64-unknown-linux-musl' >&2 ; \
      echo aarch64-unknown-linux-musl ; \
    else \
      echo "*** unknown target platform ${TARGETPLATFORM}, exiting" >&2 ; \
      exit 1 ; \
    fi` ; \
    rustup target add "$RUSTUP_TARGET" ; \
    rustup set default-host "$RUSTUP_TARGET"

# install cargo utilities
RUN if echo "$RUST_RUN_AUDIT" | grep -qP '^true$' || echo "$RUST_AUDITABLE_BINARY" | grep -qP '^true$' ; then \
      echo "*** installing audit utilities..." >&2 ; \
      cargo install cargo-audit cargo-auditable rust-audit-info ; \
    else \
      echo "*** not installing audit utilities..." >&2 ; \
    fi

# create source directory, run as same uid/gid as host user, copy files into source directory
RUN install -d /usr/src/app
WORKDIR /usr/src/app/
COPY . /usr/src/app/

# run tests
ARG RUST_RUN_TESTS=true

RUN if echo "$RUST_RUN_TESTS" | grep -qP '^true$'; then \
        echo "*** running tests as per RUST_RUN_TESTS build arg..." >&2 ; \
        cargo test ; \
    else \
        echo "*** skipping tests as per RUST_RUN_TESTS build arg..." >&2 ; \
    fi

# run audit
ARG RUST_RUN_AUDIT=true

RUN if echo "$RUST_RUN_AUDIT" | grep -qP '^true$' ; then \
        echo "*** running audit as per RUST_RUN_AUDIT build arg..." >&2 ; \
        cargo audit ; \
    else \
        echo "*** skipping audit as per RUST_RUN_AUDIT build arg..." >&2 ; \
    fi

# build the static binary in release mode
ARG RUST_AUDITABLE_BINARY=true

RUN if echo "$RUST_AUDITABLE_BINARY" | grep -qP '^true$' ; then \
        echo "*** including audit info in the binary as per RUST_AUDITABLE_BINARY build arg..." >&2 ; \
        cargo auditable build --release ; \
    else \
        echo "*** excluding audit info from the binary as per RUST_AUDITABLE_BINARY build arg..." >&2 ; \
        cargo build --release ; \
    fi
# build the static validation test
RUN cargo build --release --example static-test

# if RUST_STRIP_BINARY is set, strip the binary
ARG RUST_STRIP_BINARY=false

RUN if echo "$RUST_STRIP_BINARY" | grep -qP '^true$' ; then \
      echo "*** stripping binary as per RUST_STRIP_BINARY build arg..." >&2 ; \
      strip target/release/${APP_BIN_NAME} ; \
    else \
      echo "*** not stripping binary as per RUST_STRIP_BINARY build arg..." >&2 ; \
    fi

RUN file target/release/examples/static-test

FROM alpine

# copy system requirements
COPY --from=build /usr/share/ca-certificates /usr/share/zoneinfo /usr/share/
COPY --from=build /etc/ca-certificates /etc/ssl /etc/

# copy built binaries
COPY --from=build /usr/src/app/target/release/fuzzydatetime /app
COPY --from=build /usr/src/app/target/release/examples/static-test /app-static-test

RUN ls /

# ensure that we have the runtime dependencies we need
RUN ["/app-static-test", "--self-destruct"]

ENTRYPOINT ["/app"]
