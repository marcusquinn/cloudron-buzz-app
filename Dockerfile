# syntax=docker/dockerfile:1.7
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

FROM --platform=linux/amd64 ghcr.io/block/buzz:sha-dad5a33@sha256:c8a9e3f2cbdfb71bb72e1fc2669dd3dad0ca084caa460352fde78ca2af5de9b5 AS buzz
FROM docker.io/pgsty/silo:RELEASE.2026-09-16T00-00-00Z@sha256:635197cb9f36d01bee221d34d1c7d7960f6a95c48b0b6c01d99cd13bdae51a46 AS silo

FROM cloudron/base:6.0.0@sha256:9bed4c8fa880645f8e669041ee28febe941481d00e9445e3e5a5483cb541d09b

LABEL org.opencontainers.image.title="Buzz for Cloudron"
LABEL org.opencontainers.image.description="Cloudron package for the Buzz human-agent collaboration workspace"
LABEL org.opencontainers.image.source="https://github.com/marcusquinn/cloudron-buzz-app"
LABEL org.opencontainers.image.url="https://buzz.xyz"
LABEL org.opencontainers.image.licenses="MIT AND Apache-2.0 AND AGPL-3.0-or-later"

RUN mkdir -p /app/code/bin /srv/buzz/web /srv/buzz/admin-web /usr/share/licenses/buzz /usr/share/licenses/silo

COPY --from=buzz /usr/local/bin/buzz-relay /app/code/bin/buzz-relay
COPY --from=buzz /usr/local/bin/buzz-admin /app/code/bin/buzz-admin
COPY --from=buzz /usr/local/bin/buzz-pair-relay /app/code/bin/buzz-pair-relay
COPY --from=buzz /srv/buzz/web/ /srv/buzz/web/
COPY --from=buzz /srv/buzz/admin-web/ /srv/buzz/admin-web/

COPY --from=silo /usr/bin/silo /app/code/bin/silo
COPY --from=silo /usr/bin/mcli /app/code/bin/mcli
COPY --from=silo /licenses/LICENSE /usr/share/licenses/silo/LICENSE
COPY --from=silo /licenses/CREDITS /usr/share/licenses/silo/CREDITS
COPY --from=silo /licenses/NOTICE /usr/share/licenses/silo/NOTICE

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
COPY start.sh run-minio.sh run-rustfs.sh storage-migrate.sh run-pairing-relay.sh run-relay.sh buzz-ctl nginx.conf supervisord.conf /app/code/

RUN chmod 0755 /app/code/run-rustfs.sh /app/code/storage-migrate.sh

RUN chmod 0755 /app/code/start.sh /app/code/run-minio.sh /app/code/run-pairing-relay.sh /app/code/run-relay.sh /app/code/buzz-ctl /app/code/bin/buzz-relay /app/code/bin/buzz-admin /app/code/bin/buzz-pair-relay /app/code/bin/silo /app/code/bin/mcli

EXPOSE 3000

CMD ["/app/code/start.sh"]
