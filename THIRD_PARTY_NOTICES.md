# Third-party notices

This package redistributes unmodified binaries and web assets from pinned
upstream container images and release archives.

## RustFS

- Source: <https://github.com/rustfs/rustfs>
- Release: `1.0.1` (2026-10-03)
- Asset: `rustfs-linux-x86_64-musl-v1.0.1.zip`
- SHA-256: `a834096dafa1f1a55825a2cdaf49d006a193978d344f2d508c2be475133738a3`
- Provenance: checked against the release `SHA256SUMS`; Docker verifies the
  pinned digest before extracting the unmodified binary. The musl build avoids
  dependence on the Cloudron base's glibc version.
- License: Apache License 2.0; bundled in `/usr/share/licenses/rustfs/LICENSE`.

Silo and its legacy data remain for a few releases for migration and rollback
access to pre-migration objects, with removal in a later release.

## Buzz

- Project: Buzz by Block, Inc.
- Source: <https://github.com/block/buzz>
- Release: `desktop-v0.5.23`
- Release commit: `b9392d9d78744df365f9276e1ffe8c1baa5ea903`
- Image revision: `dad5a33865fc81a2e55b3b60746632f615ec1e3a`
- Image: `ghcr.io/block/buzz:sha-dad5a33@sha256:c8a9e3f2cbdfb71bb72e1fc2669dd3dad0ca084caa460352fde78ca2af5de9b5`
- Linux/amd64 manifest: `sha256:4f0688c778d551f118b1b654342e0ae298c23b0748119f075cc13c1e99ba4130`
- Provenance: independently registry-inspected; the OCI revision label matches
  the image revision, which is the immediate ancestor of the upstream
  `desktop-v0.5.23` release-only tag commit.
- License: Apache License 2.0; see `LICENSES/Apache-2.0.txt`.

The Buzz name and related marks belong to their respective owners. This
Cloudron package is not represented as an official Block distribution.

## PGSTY Silo server and client

- Project: PGSTY Silo, based on MinIO technology.
- Source: <https://github.com/pgsty/silo>
- Release: `RELEASE.2026-09-16T00-00-00Z`
- Server commit: `2a4d51406b7ed87af5fe6fe0f801f3290f96eb3c`
- Client commit: `e952aa78f10a2b77dd525a2b7e3143bcda0cd377`
- Image: `docker.io/pgsty/silo:RELEASE.2026-09-16T00-00-00Z@sha256:635197cb9f36d01bee221d34d1c7d7960f6a95c48b0b6c01d99cd13bdae51a46`
- Linux/amd64 manifest: `sha256:39aab3c365848e32aca7b76c5b57f86d1cbca02d7b8f24e1fd1feff9fedddae5`
- Provenance: index digest resolved with `docker buildx imagetools inspect`;
  binary versions and paths inspected inside the pinned Linux/amd64 image.
- License: GNU Affero General Public License v3 or later (AGPL-3.0-or-later).
- Copyright: 2015-2025 MinIO, Inc.; modifications 2025-2026 PGSTY.

Silo replaces the withdrawn upstream MinIO community images. The image's
`/usr/bin/silo` and `/usr/bin/mcli` are copied unmodified to `/app/code/bin`.
Its `LICENSE`, `CREDITS`, and `NOTICE` files are copied from `/licenses` into
`/usr/share/licenses/silo` in the final application image.
