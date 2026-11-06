# syntax=docker/dockerfile:1.7
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

FROM --platform=linux/amd64 ghcr.io/block/buzz:sha-2cd40ba@sha256:1155b29cdcfdcb464ca42c73db7e4dbdc6680775d1c0d6aad26ab737a3fd0cfa AS buzz

FROM cloudron/base:6.0.1@sha256:7b1e729960c3ca312d26e886917ba89483241bba0219ff292858e10d9d5768ee

LABEL org.opencontainers.image.title="Buzz for Cloudron"
LABEL org.opencontainers.image.description="Cloudron package for the Buzz human-agent collaboration workspace"
LABEL org.opencontainers.image.source="https://github.com/marcusquinn/cloudron-buzz-app"
LABEL org.opencontainers.image.url="https://buzz.xyz"
LABEL org.opencontainers.image.licenses="MIT AND Apache-2.0"

RUN mkdir -p /app/code/bin /srv/buzz/web /srv/buzz/admin-web /usr/share/licenses/buzz

COPY --from=buzz /usr/local/bin/buzz-relay /app/code/bin/buzz-relay
COPY --from=buzz /usr/local/bin/buzz-admin /app/code/bin/buzz-admin
COPY --from=buzz /usr/local/bin/buzz-pair-relay /app/code/bin/buzz-pair-relay
COPY --from=buzz /srv/buzz/web/ /srv/buzz/web/
COPY --from=buzz /srv/buzz/admin-web/ /srv/buzz/admin-web/

# musl avoids coupling the release binary to the Cloudron base's glibc version.
# Checked against the 1.0.1 release SHA256SUMS (not the mutable latest asset).
ARG RUSTFS_SHA256=a834096dafa1f1a55825a2cdaf49d006a193978d344f2d508c2be475133738a3
RUN curl --fail --location --retry 3 https://github.com/rustfs/rustfs/releases/download/1.0.1/rustfs-linux-x86_64-musl-v1.0.1.zip -o /run/rustfs.zip \
    && printf '%s  /run/rustfs.zip\n' "$RUSTFS_SHA256" | sha256sum -c - \
    && unzip /run/rustfs.zip -d /run/rustfs-release \
    && install -m 0755 /run/rustfs-release/rustfs /app/code/bin/rustfs \
    && rm -rf /run/rustfs.zip /run/rustfs-release

COPY LICENSES/Apache-2.0.txt /usr/share/licenses/buzz/LICENSE
COPY LICENSES/Apache-2.0.txt /usr/share/licenses/rustfs/LICENSE
COPY CloudronManifest.json /app/code/CloudronManifest.json
COPY LICENSE /app/code/LICENSE
COPY THIRD_PARTY_NOTICES.md /app/code/THIRD_PARTY_NOTICES.md
COPY start.sh run-rustfs.sh storage-setup.sh run-pairing-relay.sh run-relay.sh buzz-ctl nginx.conf supervisord.conf /app/code/

RUN chmod 0755 /app/code/start.sh /app/code/run-rustfs.sh /app/code/storage-setup.sh /app/code/run-pairing-relay.sh /app/code/run-relay.sh /app/code/buzz-ctl /app/code/bin/buzz-relay /app/code/bin/buzz-admin /app/code/bin/buzz-pair-relay

EXPOSE 3000

CMD ["/app/code/start.sh"]
