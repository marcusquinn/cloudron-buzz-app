# Third-party notices

This package redistributes unmodified binaries and web assets from pinned
upstream container images.

## Buzz

- Project: Buzz by Block, Inc.
- Source: <https://github.com/block/buzz>
- Release: `desktop-v0.5.18`
- Release commit: `39f8b46935736334cdd7045a4e4b5d7eb1a33888`
- Image revision: `aea0ef8df9fc24d9aa8bf5c761ab2910026a601b`
- Image: `ghcr.io/block/buzz:sha-aea0ef8@sha256:6e26d9653eaf485182229930a02760e1f70ebfe1570fcbadbb1a436d73e2e647`
- Linux/amd64 manifest: `sha256:a3294fed2e0a102b99471ca28e139327a90a69070ad9be62397d081e81551cfe`
- Provenance: independently registry-inspected; the OCI revision label matches
  the image revision, which is the immediate ancestor of the upstream
  `desktop-v0.5.18` release-only tag commit.
- License: Apache License 2.0; see `LICENSES/Apache-2.0.txt`.

The Buzz name and related marks belong to their respective owners. This
Cloudron package is not represented as an official Block distribution.

## MinIO server

- Release: `RELEASE.2025-09-07T16-13-09Z`
- Commit: `07c3a429bfed433e49018cb0f78a52145d4bedeb`
- Image: `minio/minio:RELEASE.2025-09-07T16-13-09Z@sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2`
- License: GNU Affero General Public License v3.

## MinIO client

- Release: `RELEASE.2025-08-13T08-35-41Z`
- Commit: `7394ce0dd2a80935aded936b09fa12cbb3cb8096`
- Image: `minio/mc:RELEASE.2025-08-13T08-35-41Z@sha256:eb4ea9884b77704230e2423e9004d2fa738dc272876b9cc41a297d29443b8780`
- License: GNU Affero General Public License v3.

The MinIO image `LICENSE` and `CREDITS` files are copied into
`/usr/share/licenses/minio` and `/usr/share/licenses/minio-client` in the final
application image.
