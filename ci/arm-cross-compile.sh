#!/bin/bash
set -euo pipefail

# Install the Rust stdlib for the current target
rustup target add $TARGET

# Download the Raspberry Pi cross-compilation toolchain if needed
if [ "$TARGET" = "arm-unknown-linux-gnueabihf" ]
then
  git clone --depth=1 https://github.com/raspberrypi/tools.git /tmp/tools
  export PATH=/tmp/tools/arm-bcm2708/arm-linux-gnueabihf/bin:$PATH
fi

# Install cross libzmq 4.3.1
git clone -b v4.3.1 https://github.com/zeromq/libzmq.git /tmp/libzmq && pushd /tmp/libzmq
./autogen.sh && ./configure --host=arm-none-linux-gnueabi CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++
make -j$(nproc) && sudo make install && sudo ldconfig && popd

# Install host protobuf 3.8.0
git clone -b v3.8.0 https://github.com/protocolbuffers/protobuf.git --recursive /tmp/protobuf && pushd /tmp/protobuf
./autogen.sh && ./configure
make -j$(nproc) && sudo make install && sudo ldconfig && popd

# Install protobuf-codegen
cargo install --force protobuf-codegen

# Generate protobuf .rs code
protoc --rust_out=src/ proto/falcon.proto

# Compile the binary for the current target
cargo build --target=$TARGET --release

# Package up the release binary
tar -C target/$TARGET/release -czf $TARGET.tar.gz rservice
