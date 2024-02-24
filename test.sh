#!/bin/bash
set -ex

docker_build() {
  echo "Arch: $ARCH"
  echo "Platform: $PLATFORM"

  # NB: add -vv to cargo build when debugging
  local -r crate="$1"crate
  docker run --rm \
    -v "$PWD/test/${crate}:/volume" \
    -v cargo-cache:/root/.cargo/registry \
    -e RUST_BACKTRACE=1 \
    --platform $PLATFORM
    rustmusl-temp \
    cargo build

  cd "test/${crate}"

  docker run --rm \
    -v "$PWD:/volume" \
    -t ubuntu:latest
    --platform $PLATFORM \
    /volume/target/$ARCH-unknown-linux-musl/debug/"${crate}"

  ldd "target/x86_64-unknown-linux-musl/debug/${crate}" 2>&1 | grep -qE "not a dynamic|statically linked" && \
    echo "${crate} is a static executable"
}

# Helper to check how ekidd/rust-musl-builder does it
docker_build_ekidd() {
  local -r crate="$1"crate
  docker run --rm \
    -v "$PWD/test/${crate}:/home/rust/src" \
    -v cargo-cache:/home/rust/.cargo \
    -e RUST_BACKTRACE=1 \
    -it ekidd/rust-musl-builder:nightly \
    cargo build -vv
  cd "test/${crate}"
  ./target/x86_64-unknown-linux-musl/debug/"${crate}"
  ldd "target/x86_64-unknown-linux-musl/debug/${crate}" 2>&1 | grep -qE "not a dynamic|statically linked" && \
    echo "${crate} is a static executable"
}

# Helper to check how golddranks/rust_musl_docker does it
docker_build_golddranks() {
  local -r crate="$1"crate
  docker run --rm \
    -v "$PWD/test/${crate}:/workdir" \
    -e RUST_BACKTRACE=1 \
    -it golddranks/rust_musl_docker:nightly-2017-10-03 \
    cargo build -vv --target=x86_64-unknown-linux-musl
  cd "test/${crate}"
  ./target/x86_64-unknown-linux-musl/debug/"${crate}"
  ldd "target/x86_64-unknown-linux-musl/debug/${crate}" 2>&1 | grep -qE "not a dynamic|statically linked" && \
    echo "${crate} is a static executable"
}

docker_build "$1"
