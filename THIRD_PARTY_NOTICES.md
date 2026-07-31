# Third-party notices

This package redistributes unmodified binaries and web assets from pinned
upstream container images.

## Buzz

- Project: Buzz by Block, Inc.
- Source: <https://github.com/block/buzz>
- Release: `v0.5.2`
- Commit: `3e48f1b2365d326ee1c9582448d86a99b44ecd5d`
- Image: `ghcr.io/block/buzz:sha-3e48f1b@sha256:12763e38fd99fe8f4e63466a08ea8e3afbda4da0ebd1f51f0b57d78f9b082abe`
- Linux/amd64 manifest: `sha256:ebd7764efbdc225dea573331cd910b62cb7a3a1b675e89345714314f608a6f39`
- Provenance: independently registry-inspected; the OCI revision label and
  upstream `v0.5.2` tag both resolve to the commit above.
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
