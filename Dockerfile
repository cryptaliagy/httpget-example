# Can use latest-tls or a specific version's tag, also
FROM ghcr.io/taliamax/httpget:latest as httpget

FROM rust:1.70.0 as build

RUN rustup target add $(arch)-unknown-linux-musl && \
    apt-get update && \
    apt-get install -y musl-tools

WORKDIR /app

COPY . .

RUN mkdir ./bin

# Use a statically linked target for the prod
RUN cargo build --release --target $(arch)-unknown-linux-musl \
    && mv ./target/$(arch)-unknown-linux-musl/release/httpget-example ./bin/httpget-example

COPY --from=httpget /httpget /app/bin/httpget

FROM scratch as runner

COPY --from=build /app/bin /bin

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/bin/httpget", "http://localhost:8080/healthz"]

CMD ["/bin/httpget-example"]
