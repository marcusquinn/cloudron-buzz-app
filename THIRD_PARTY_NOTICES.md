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

Package 0.1.27 removed the PGSTY Silo (MinIO) server and `mcli` client that
earlier releases bundled under AGPL-3.0-or-later for the RustFS migration. No
AGPL component remains in the image.

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
