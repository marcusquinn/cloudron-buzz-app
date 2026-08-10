# syntax=docker/dockerfile:1.7
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

FROM --platform=linux/amd64 ghcr.io/block/buzz:sha-6a17d03@sha256:ce87d6d4ce39cc9e3bd19d356b05179d64a39e30c0d0fe1630b18ab1ed0963b8 AS buzz
FROM minio/minio:RELEASE.2025-09-07T16-13-09Z@sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2 AS minio
FROM minio/mc:RELEASE.2025-08-13T08-35-41Z@sha256:eb4ea9884b77704230e2423e9004d2fa738dc272876b9cc41a297d29443b8780 AS minio-client

FROM cloudron/base:5.1.0@sha256:1c0666c9abe9e2090d33686826d4e97769b799124573118d41e0d7485135748e

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
COPY start.sh run-minio.sh run-pairing-relay.sh run-relay.sh buzz-ctl nginx.conf supervisord.conf /app/code/

RUN chmod 0755 /app/code/start.sh /app/code/run-minio.sh /app/code/run-pairing-relay.sh /app/code/run-relay.sh /app/code/buzz-ctl /app/code/bin/buzz-relay /app/code/bin/buzz-admin /app/code/bin/buzz-pair-relay /app/code/bin/minio /app/code/bin/mc

EXPOSE 3000

CMD ["/app/code/start.sh"]
