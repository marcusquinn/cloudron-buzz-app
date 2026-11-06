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
- Base release: `desktop-v0.5.28` (release-only tag commit `f87c10895ea35a9a2cea629fef1d7532a3fecbc5`)
- NIP-CL relay commit: `d28f6b2f7095b50a2c987a42e9b4ca345f8e9dac`
- Image revision: `2cd40badb85de059a6916206e133da7a0a88fb2e`
- Image: `ghcr.io/block/buzz:sha-2cd40ba@sha256:1155b29cdcfdcb464ca42c73db7e4dbdc6680775d1c0d6aad26ab737a3fd0cfa`
- Linux/amd64 manifest: `sha256:6ff07e58c605ad5c77c5c4ae6ad4ed73bcb89d2734287254ab563ed03a138330`
- Provenance: independently registry-inspected; the OCI revision label matches
  the image revision, which is an upstream `main` commit containing the NIP-CL
  relay commit (no release tag contains it yet).
- License: Apache License 2.0; see `LICENSES/Apache-2.0.txt`.

The Buzz name and related marks belong to their respective owners. This
Cloudron package is not represented as an official Block distribution.
