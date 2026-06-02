# Pterodactyl-compatible Node.js 20 image with Chromium/Playwright system libraries.
# Derived from parkervcp/yolks so the container user (uid 1001) and entrypoint are identical;
# existing /home/container data (node_modules, ~/.cache/ms-playwright) remains valid.
#
# Published by .github/workflows/build-nodejs-playwright.yml as a tag on this repo's
# already-public ghcr package:
#   ghcr.io/rainerstudios/sbox-native-linux:nodejs-playwright-20
FROM ghcr.io/parkervcp/yolks:nodejs_20

USER root

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 \
      libgtk-3-0 libgdk-pixbuf-2.0-0 \
      libnss3 libnspr4 \
      libcups2 libdbus-1-3 libglib2.0-0 \
      libgbm1 libdrm2 \
      libx11-6 libxcb1 libxext6 libxi6 libxtst6 \
      libxss1 libxdamage1 libxrandr2 libxcomposite1 libxfixes3 \
      libxkbcommon0 libxshmfence1 libxcursor1 \
      libpango-1.0-0 libpangocairo-1.0-0 libcairo2 libcairo-gobject2 \
      libasound2 \
      libwayland-client0 \
      fonts-liberation fonts-noto-color-emoji ca-certificates \
 && rm -rf /var/lib/apt/lists/*

USER container
WORKDIR /home/container
