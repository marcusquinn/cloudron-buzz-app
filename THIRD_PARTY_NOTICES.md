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
- Source: <https://github.com/block/buzz> (relay, admin CLI, pairing relay and
  web assets)
- Supported desktop app: the Buzz release from <https://github.com/block/buzz-app>
  named by `upstreamVersion` in `CloudronManifest.json`
- NIP-CL relay commit: `d28f6b2f7095b50a2c987a42e9b4ca345f8e9dac`
- Image, image revision, linux/amd64 manifest and the desktop release's pinned
  relay revision: the `readonly` constants in `test/verify-buzz-image.sh`; the
  `Dockerfile` pins the same `ghcr.io/block/buzz` image by digest
- Provenance: independently registry-inspected; the OCI revision label matches
  the image revision, an upstream `main` commit that contains both the NIP-CL
  relay commit and the Buzz app's pinned relay revision. Upstream's SLSA
  provenance and deployment-eligibility attestations were verified for this
  index and revision.
- License: Apache License 2.0; see `LICENSES/Apache-2.0.txt`.

The Buzz name and related marks belong to their respective owners. This
Cloudron package is not represented as an official Block distribution.
