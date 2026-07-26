# syntax=docker/dockerfile:1.7
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

FROM --platform=linux/amd64 ghcr.io/block/buzz:sha-0096d71@sha256:32a8c6aa8ca3617d767eb5743891f45d956c9cdbe161d244c8702a7645b64a78 AS buzz
FROM minio/minio:RELEASE.2025-09-07T16-13-09Z@sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2 AS minio
FROM minio/mc:RELEASE.2025-08-13T08-35-41Z@sha256:eb4ea9884b77704230e2423e9004d2fa738dc272876b9cc41a297d29443b8780 AS minio-client

FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

LABEL org.opencontainers.image.title="Buzz for Cloudron"
LABEL org.opencontainers.image.description="Cloudron package for the Buzz human-agent collaboration workspace"
LABEL org.opencontainers.image.source="https://github.com/marcusquinn/cloudron-buzz-app"
LABEL org.opencontainers.image.url="https://buzz.xyz"
LABEL org.opencontainers.image.licenses="MIT AND Apache-2.0 AND AGPL-3.0-only"

RUN mkdir -p /app/code/bin /srv/buzz/web /srv/buzz/admin-web /usr/share/licenses/buzz /usr/share/licenses/minio /usr/share/licenses/minio-client

COPY --from=buzz /usr/local/bin/buzz-relay /app/code/bin/buzz-relay
COPY --from=buzz /usr/local/bin/buzz-admin /app/code/bin/buzz-admin
COPY --from=buzz /usr/local/bin/buzz-pair-relay /app/code/bin/buzz-pair-relay
COPY --from=buzz /srv/buzz/web/ /srv/buzz/web/
COPY --from=buzz /srv/buzz/admin-web/ /srv/buzz/admin-web/

COPY --from=minio /usr/bin/minio /app/code/bin/minio
COPY --from=minio /licenses/LICENSE /usr/share/licenses/minio/LICENSE
COPY --from=minio /licenses/CREDITS /usr/share/licenses/minio/CREDITS
COPY --from=minio-client /usr/bin/mc /app/code/bin/mc
COPY --from=minio-client /licenses/LICENSE /usr/share/licenses/minio-client/LICENSE
COPY --from=minio-client /licenses/CREDITS /usr/share/licenses/minio-client/CREDITS

COPY LICENSES/Apache-2.0.txt /usr/share/licenses/buzz/LICENSE
COPY LICENSE /app/code/LICENSE
COPY THIRD_PARTY_NOTICES.md /app/code/THIRD_PARTY_NOTICES.md
COPY start.sh run-minio.sh run-relay.sh buzz-ctl supervisord.conf /app/code/

RUN chmod 0755 /app/code/start.sh /app/code/run-minio.sh /app/code/run-relay.sh /app/code/buzz-ctl /app/code/bin/buzz-relay /app/code/bin/buzz-admin /app/code/bin/buzz-pair-relay /app/code/bin/minio /app/code/bin/mc

EXPOSE 3000

CMD ["/app/code/start.sh"]
