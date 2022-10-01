FROM rust:latest as build

ENV APP_BIN_NAME=fuzzy-datetime
ENV MIN_BUILD_DATE=2022-09-30

# install system dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential libssl-dev libcurl4-openssl-dev musl musl-dev \
        musl-tools && \
    DEBIAN_FRONTEND=noninteractive apt-get update -y

RUN /usr/sbin/update-ca-certificates

# install the x86_64-unknown-linux-musl target
RUN rustup target add x86_64-unknown-linux-musl

# install cargo audit
RUN cargo install cargo-audit cargo-auditable rust-audit-info

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
        cargo auditable build --target x86_64-unknown-linux-musl --release ; \
    else \
        echo "*** excluding audit info from the binary as per RUST_AUDITABLE_BINARY build arg..." >&2 ; \
        cargo build --target x86_64-unknown-linux-musl --release ; \
    fi
# build the static validation test
RUN cargo build --target x86_64-unknown-linux-musl --release --example static-test

# if RUST_STRIP_BINARY is set, strip the binary
ARG RUST_STRIP_BINARY=false

RUN if echo "$RUST_STRIP_BINARY" | grep -qP '^true$' ; then \
      echo "*** stripping binary as per RUST_STRIP_BINARY build arg..." >&2 ; \
      strip target/x86_64-unknown-linux-musl/release/${APP_BIN_NAME} ; \
    else \
      echo "*** not stripping binary as per RUST_STRIP_BINARY build arg..." >&2 ; \
    fi

FROM scratch

# copy system requirements
COPY --from=build /usr/share/ca-certificates /usr/share/zoneinfo /usr/share/
COPY --from=build /etc/ca-certificates /etc/ssl /etc/

# copy built binaries
COPY --from=build /usr/src/app/target/x86_64-unknown-linux-musl/release/fuzzydatetime /app
COPY --from=build /usr/src/app/target/x86_64-unknown-linux-musl/release/examples/static-test /app-static-test

# ensure that we have the runtime dependencies we need
RUN ["/app-static-test", "--self-destruct"]

ENTRYPOINT ["/app"]
