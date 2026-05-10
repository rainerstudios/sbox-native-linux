# ─────────────────────────────────────────────────────────────────────────────
# s&box Native Linux Dedicated Server — Pterodactyl/Pelican Yolk
#
# Based on Ubuntu 24.04 (Noble) which ships glibc 2.39 — satisfying the
# glibc ≥ 2.38 and GLIBCXX ≥ 3.4.31 requirement of Source 2 engine binaries
# shipped in s&box's bin/linuxsteamrt64/ depot.
#
# Build:
#   docker build --platform linux/amd64 \
#     -t ghcr.io/hyberhost/sbox-native-linux:latest .
#
# Designed for Pterodactyl Panel / Pelican Panel egg system.
# ─────────────────────────────────────────────────────────────────────────────

FROM ubuntu:noble

LABEL maintainer="steven.smith@hyberhost.com"
LABEL description="s&box Native Linux Dedicated Server (no Wine)"
LABEL org.opencontainers.image.source="https://github.com/rainerstudios/sbox-native-linux"

ARG DEBIAN_FRONTEND=noninteractive
ARG PUID=999
ARG PGID=999
ARG DOTNET_CHANNEL=10.0

# ── System packages ──────────────────────────────────────────────────────────
# Core: curl, ca-certificates, lib32gcc-s1 (SteamCMD requirement)
# Vulkan: libvulkan1 (Source 2 renderer, even headless servers probe it)
# Audio stubs: libopenal1, libpulse0 (Source 2 audio init)
# Misc: locales, iproute2 (Pterodactyl entrypoint uses `ip` command)
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        fontconfig \
        iproute2 \
        lib32gcc-s1 \
        libatomic1 \
        libcurl4 \
        libfontconfig1 \
        libfreetype6 \
        libgcc-s1 \
        libicu74 \
        libopenal1 \
        libpulse0 \
        libsdl2-2.0-0 \
        libstdc++6 \
        libvulkan1 \
        locales \
        ncurses-base \
        tar \
        wget \
        xdg-user-dirs \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ── SteamCMD ─────────────────────────────────────────────────────────────────
# SteamCMD must be run from its own directory because steamcmd.sh resolves
# linux32/steamcmd relative to its location. A wrapper script handles this.
RUN mkdir -p /opt/steamcmd \
    && curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
       | tar -xzf - -C /opt/steamcmd \
    && chmod 0755 /opt/steamcmd/steamcmd.sh \
    && printf '#!/bin/bash\nexec /opt/steamcmd/steamcmd.sh "$@"\n' \
       > /usr/local/bin/steamcmd \
    && chmod 0755 /usr/local/bin/steamcmd \
    # Bootstrap SteamCMD (downloads runtime files)
    && /opt/steamcmd/steamcmd.sh +quit || true \
    && mkdir -p /home/container/.steam \
    && ln -s /opt/steamcmd /home/container/.steam/steamcmd

# ── .NET Runtime ─────────────────────────────────────────────────────────────
# Install Microsoft's .NET runtime via the official install script.
# s&box uses .NET 10; the channel can be overridden at build time.
RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh \
        --channel ${DOTNET_CHANNEL} \
        --runtime dotnet \
        --install-dir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet \
    && rm /tmp/dotnet-install.sh \
    && dotnet --info

ENV DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1

# ── OpenSSL ABI fix ────────────────────────────────────────────────────────
# Steam bundles older OpenSSL in bin/linuxsteamrt64/. When that directory is
# on LD_LIBRARY_PATH, .NET's TLS shim picks up Steam's old OpenSSL instead of
# the system's OpenSSL 3, causing ABI mismatches that break HTTPS requests.
# LD_PRELOAD forces the correct system libraries to be loaded first.
# The entrypoint also sets this at runtime, but having it in ENV ensures it
# applies even if entrypoint is bypassed.
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libcrypto.so.3:/usr/lib/x86_64-linux-gnu/libssl.so.3

# ── Pterodactyl user & directories ───────────────────────────────────────────
RUN groupadd -g ${PGID} container 2>/dev/null || true \
    && useradd -u ${PUID} -g ${PGID} -d /home/container -s /bin/bash container 2>/dev/null || true \
    && mkdir -p /home/container \
    && chown -R ${PUID}:${PGID} /home/container \
    # Allow container user to symlink engine .so files into dotnet root at runtime
    && chmod 0777 /usr/share/dotnet

# ── s&box launch script ─────────────────────────────────────────────────────
# Baked into the image so the egg startup can simply be: bash start-sbox-native
COPY start-sbox-native /usr/local/bin/start-sbox-native
RUN chmod 0755 /usr/local/bin/start-sbox-native

# ── Entrypoint ───────────────────────────────────────────────────────────────
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

USER ${PUID}:${PGID}
ENV HOME=/home/container \
    USER=container \
    TERM=xterm \
    COLUMNS=80 \
    LINES=24
WORKDIR /home/container

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
