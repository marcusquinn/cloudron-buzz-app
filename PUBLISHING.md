# Cloudron community publishing

`CloudronVersions.json` contains the independently published package history.
Never hand-write an image tag or digest into the catalog.

Merging a reviewed package-version change to `main` is the repository's
standing publication authorization. The `Publish Cloudron Catalog` workflow
then performs the deterministic release mechanics; the upstream monitor itself
still only opens upgrade work and never publishes directly.

## Automated release workflow

For a manifest version that is not yet in the catalog, the workflow:

1. Re-runs package, ShellCheck, and upstream image-provenance checks.
2. Builds and pushes a `linux/amd64` package image to GHCR.
3. Resolves the registry digest and proves the image is anonymously readable.
4. Runs `scripts/publish-cloudron-catalog.sh`, which uses
   `cloudron versions add --image=<DIGEST> --state=testing` and then promotes
   that exact entry with
   `cloudron versions update --image=<DIGEST> --version=<VERSION> --state=published`.
5. Re-runs package checks and exact catalog assertions.
6. Fails if `main` advanced, otherwise atomically pushes the generated catalog
   commit and matching `v<VERSION>` tag, then creates the GitHub release.

The catalog stores the immutable digest reference, not a mutable image tag.
Concurrency is serialized and all state changes fail closed. A failed run can
be retried with the workflow's manual dispatch after resolving the reported
gate; never bypass a failed provenance, anonymous-pull, or catalog assertion.

## Manual release fallback

1. Finish the package release and update `CloudronManifest.json`, `CHANGELOG`,
   and `CHANGELOG.md` together.
2. Confirm `icon.png` is a 256×256 PNG and `media/hero.png` is a
   privacy-reviewed 3:1 image. Verify every `iconUrl` and `mediaLinks` URL
   returns an image over public HTTPS.
3. Configure an operator-owned registry and run `cloudron build`. Use
   `cloudron build info` to verify the recorded repository and image.
4. Add the candidate with `cloudron versions add --state testing`, host the
   catalog at the intended public URL, and run `cloudron versions list`.
5. Test a clean install with
   `cloudron install --versions-url <PUBLIC_VERSIONS_URL> --location buzz-test`.
   Also verify upgrade, restart, health checks, and backup/restore.
6. Promote only the tested package with
   `cloudron versions update --version=<VERSION> --state=published`, then
   publish the updated catalog.
7. Optionally sign in to [Cloudron Community Apps](https://ca.cloudron.io), add
   the same versions URL, and verify the imported icon, screenshot/hero,
   description, changelog, and install URL.

Published entries are append-only. For a critical bad release, run
`cloudron versions revoke`, bump the package version, rebuild, and add a new
entry. Do not mutate the manifest or image of a published version.

Cloudron validates the complete catalog before selecting a compatible version.
Every historical manifest must therefore remain parseable by the oldest
supported Cloudron release. Do not add fields introduced by a newer Cloudron
to any catalog entry while older releases remain supported. The append-only
rule has one narrow exception: incompatible catalog metadata may be corrected
only when it otherwise makes the complete catalog unusable. Published images
and runtime package contents remain immutable.

## Visual assets

- `icon.png`: canonical 256×256 package icon.
- `media/hero.png`: canonical 1568×523 3:1 listing image.
- `CloudronManifest.json` records the current public HTTPS assets. Prefer a
  package-controlled stable URL when replacing either reference.
