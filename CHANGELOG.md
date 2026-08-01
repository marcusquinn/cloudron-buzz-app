# Changelog

## [Unreleased]

## [0.1.9] - 2026-08-01

### Changed

- Upgrade the pinned Buzz relay and web assets from `v0.5.2` to
  `desktop-v0.5.3`, including upstream relay, Git, storage, shared-compute, and
  client reliability refinements.
- Refresh the immutable image, release-tag, and OCI revision provenance checks.

## [0.1.8] - 2026-07-31

### Changed

- Upgrade the pinned Buzz relay and web assets from `v0.5.0` to `v0.5.2`,
  including upstream community-invite, shared-agent, and client reliability
  refinements.
- Refresh the immutable image, release-tag, and OCI revision provenance checks.

## [0.1.7] - 2026-07-28

### Added

- Add guarded main-branch publication that builds a public, immutable
  `linux/amd64` GHCR image, generates the catalog entry with the Cloudron CLI,
  and atomically publishes the catalog commit and package tag.

### Changed

- Upgrade the pinned Buzz relay and web assets from `v0.4.26` to `v0.5.0`,
  including use-limited invites, richer search filters, and relay reliability
  improvements.

### Security

- Include upstream `nostr` 0.44.6, which addresses RUSTSEC-2026-0216 in NIP-44
  payload handling.

## [0.1.6] - 2026-07-26

### Changed

- Upgrade the pinned Buzz relay and web assets from `v0.4.25` to `v0.4.26`,
  including upstream community-management and mobile-pairing refinements.

## [0.1.5] - 2026-07-25

### Changed

- Upgrade the pinned Buzz relay and web assets from `v0.4.24` to `v0.4.25`,
  including upstream community-icon controls and client reliability fixes.

## [0.1.4] - 2026-07-24

### Fixed

- Restored Cloudron 9.1 and 9.2 installation and update compatibility by
  temporarily omitting `packageUrl` until Cloudron 10.0.0 is numerically
  available.

## [0.1.3] - 2026-07-24

### Changed

- Upgrade the pinned Buzz relay and web assets from `v0.4.22` to `v0.4.24`,
  including upstream Redis pool sizing and media, channel, and reconnect fixes.

## [0.1.2] - 2026-07-24

### Added

- Cloudron community catalog metadata, publishing runbook, and
  privacy-reviewed 3:1 screenshot hero.

### Changed

- Require Cloudron `9.1.0` for community-package publishing metadata.

## [0.1.1] - 2026-07-22

### Added in 0.1.1

- Managed, SHA-pinned GitHub release validation for explicit `v*` tags.
- Buzz Desktop `v0.4.22` screenshot gallery with privacy review notes.
- Upstream provenance, deployment-admin isolation, public-surface security, and
  private vulnerability-reporting guidance.
- Agent guidance for private-community onboarding using public Nostr identities
  only.

### Changed

- Clarified first-owner setup for self-hosted relays and the public NIP-11,
  readiness, invite, and Git-forge surfaces.
- Added public-source regression checks that reject tracked symlinks and
  absolute user home-directory paths.

### Removed

- Local-only agent command symlink from the published source tree.

## 0.1.0 - 2026-07-22

### Added

- Initial private Cloudron package for Buzz `v0.4.22`.
- Pinned Buzz, MinIO, MinIO client, and Cloudron base image digests.
- Cloudron PostgreSQL, Redis, and local-storage integration.
- Private bundled MinIO object storage for media and Git packfiles.
- Stable relay identity, closed membership, NIP-98 HTTP authentication,
  NIP-OA agent delegation, and authenticated media reads.
- `buzz-ctl` owner and membership administration without private-key disclosure.
- Supervisor lifecycle management, readiness checks, and deployment documentation.
