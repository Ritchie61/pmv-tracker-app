# Use lightweight Linux base
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Install system dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    git curl unzip xz-utils zip libglu1-mesa \
    openjdk-11-jdk wget gnupg ca-certificates \
    clang cmake ninja-build pkg-config \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Flutter from stable channel
ARG FLUTTER_VERSION=stable
RUN git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VERSION} /usr/local/flutter
ENV PATH="$PATH:/usr/local/flutter/bin"
ENV PATH="$PATH:/usr/local/flutter/bin/cache/dart-sdk/bin"

# Enable flutter web and verify installation
RUN flutter config --enable-web \
    && flutter doctor -v \
    && flutter precache

# Set up non-root user for safety
RUN useradd -m -s /bin/bash vscode \
    && usermod -aG sudo vscode \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER vscode
WORKDIR /workspaces/pmv-tracker-png

# Default command when container starts
CMD ["/bin/bash"]
