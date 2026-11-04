# Security policy

## Supported versions

Buzz for Cloudron is experimental. Security fixes are provided only for the
latest package release and its pinned upstream Buzz version.

| Package version | Upstream Buzz | Supported |
| --- | --- | --- |
| `0.1.27` | `0.5.27` | Yes |
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
pinned Buzz and RustFS components. Upstream-only defects may be redirected to
the relevant upstream security process.

## Object-storage dependency

RustFS 1.0.1 is the only object store. It is checksum-pinned to its official
musl release asset, licensed Apache-2.0, binds to `127.0.0.1:9100`, disables the
console, and reads generated credentials from private files. Before the relay
starts, SigV4-signed `curl` requests create the `buzz-data` bucket and remove any
bucket policy. Startup then fails unless an anonymous request is refused. The
signing credentials are read from a `0600` curl config under `/run/buzz/s3`,
never from process arguments.

Package 0.1.27 removed the bundled PGSTY Silo (MinIO) server and the one-time
migration. Startup fails closed when legacy objects were never migrated, so the
relay never runs with incomplete media and Git data. Legacy `/app/data/minio` data
is never deleted automatically; `buzz-ctl storage-purge-legacy --confirm` removes
it only after a `migrated` or `not-needed` state.
