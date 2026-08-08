# Third-party notices

This package redistributes unmodified binaries and web assets from pinned
upstream container images.

## Buzz

- Project: Buzz by Block, Inc.
- Source: <https://github.com/block/buzz>
- Release: `desktop-v0.5.7`
- Release commit: `f167818d25dd9f03115ab907a16f07daee2ece5c`
- Image revision: `74b913cff8512c015dc6f1a7473b253fa803f954`
- Image: `ghcr.io/block/buzz:sha-74b913c@sha256:2d7001137aa4e61b0548f6125f555715fa9933be50280b1d3c5ea2fb6cfa7ef1`
- Linux/amd64 manifest: `sha256:804b7c2b6ed5334283a29f1e4adfa5b8d17ee5d7a2f4e0d67978212fe9b018fd`
- Provenance: independently registry-inspected; the OCI revision label matches
  the image revision, which is the immediate ancestor of the upstream
  `desktop-v0.5.7` release-only tag commit.
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
