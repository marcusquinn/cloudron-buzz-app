# Security policy

## Supported versions

Buzz for Cloudron is experimental. Security fixes are provided only for the
latest package release and its pinned upstream Buzz version.

| Package version | Upstream Buzz | Supported |
| --- | --- | --- |
| `0.1.23` | `0.5.23` | Yes |
| Earlier versions | Earlier versions | No |

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability.

Use GitHub's private vulnerability reporting from this repository's
**Security** tab. Include:

- Affected package and upstream versions.
- Reproduction steps and required privileges.
- Expected and observed behavior.
- Potential impact and any known mitigations.

If private vulnerability reporting is unavailable, use the package contact
address declared in `CloudronManifest.json` and do not include credentials,
private Nostr keys, private community content, or production data.

## Scope

Reports may cover the Cloudron packaging, runtime configuration, persistence,
authentication boundaries, deployment scripts, and interactions with the
pinned Buzz, RustFS and PGSTY Silo components. Upstream-only defects may be redirected to
the relevant upstream security process.

## Object-storage dependency

RustFS 1.0.1 is the long-term store, checksum-pinned to its official musl release
asset and licensed Apache-2.0. It binds to `127.0.0.1:9100`, disables the console,
and reads generated credentials from private files. `mcli anonymous set none`
enforces the private bucket before the relay starts.

Migration copies over authenticated S3, never opens MinIO data in RustFS, and
switches only after key/size/count verification. Failure retains Silo and retries
on restart. Silo and legacy data remain for a few releases, then will be removed.
Downgrades see only pre-migration objects; use a matching full Cloudron backup
for complete rollback. No credential values appear in migration status.

The withdrawn MinIO community images are replaced by PGSTY Silo
`RELEASE.2026-09-16T00-00-00Z`, licensed AGPL-3.0-or-later and pinned to index
digest `sha256:635197cb9f36d01bee221d34d1c7d7960f6a95c48b0b6c01d99cd13bdae51a46`.
Source and bundled licence notices are documented in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Silo retains the MinIO storage format and health routes. It uses the existing
`/app/data/minio` directory and credential files without a data migration.
The server remains loopback-only, its browser and updater are disabled, and
`mcli anonymous set none` enforces the private `buzz-data` bucket on startup.
