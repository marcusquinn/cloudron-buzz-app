# Security policy

## Supported versions

Buzz for Cloudron is experimental. Security fixes are provided only for the
latest package release and its pinned upstream Buzz version.

| Package version | Upstream Buzz | Supported |
| --- | --- | --- |
| `0.1.15` | `0.5.10` | Yes |
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
pinned Buzz and MinIO components. Upstream-only defects may be redirected to
the relevant upstream security process.
