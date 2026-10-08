# Third-party notices

This package redistributes unmodified binaries and web assets from pinned
upstream container images.

## Buzz

- Project: Buzz by Block, Inc.
- Source: <https://github.com/block/buzz>
- Release: `desktop-v0.5.27`
- Release commit: `7a2fb3cc2d401e91e67d9819741d9025278cbec0`
- Image revision: `af5bb0af488784c3707e99c87e0675a729711a6e`
- Image: `ghcr.io/block/buzz:sha-af5bb0a@sha256:a212517165be1b34de022345a109f93eab2575ed08ed48439db592ce703eff33`
- Linux/amd64 manifest: `sha256:dd998c7499d92cffbf5a71609a5231bd88d3ca0e987f03d1324bd759db57ccb7`
- Provenance: independently registry-inspected; the OCI revision label matches
  the image revision, which is the immediate ancestor of the upstream
  `desktop-v0.5.27` release-only tag commit.
- License: Apache License 2.0; see `LICENSES/Apache-2.0.txt`.

The Buzz name and related marks belong to their respective owners. This
Cloudron package is not represented as an official Block distribution.

## MinIO server

- Release: `RELEASE.2025-09-07T16-13-09Z`
- Commit: `07c3a429bfed433e49018cb0f78a52145d4bedeb`
- Image: `quay.io/minio/minio:RELEASE.2025-09-07T16-13-09Z@sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2`
- License: GNU Affero General Public License v3.

## MinIO client

- Release: `RELEASE.2025-08-13T08-35-41Z`
- Commit: `7394ce0dd2a80935aded936b09fa12cbb3cb8096`
- Image: `quay.io/minio/mc:RELEASE.2025-08-13T08-35-41Z@sha256:eb4ea9884b77704230e2423e9004d2fa738dc272876b9cc41a297d29443b8780`
- License: GNU Affero General Public License v3.

The MinIO image `LICENSE` and `CREDITS` files are copied into
`/usr/share/licenses/minio` and `/usr/share/licenses/minio-client` in the final
application image.
