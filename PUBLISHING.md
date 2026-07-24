# Cloudron community publishing

`CloudronVersions.json` is initialized but intentionally contains no release.
Publishing requires a registry-hosted image built by the Cloudron CLI and
separate operator authorization. Never hand-write an image tag or digest into
the catalog.

## Release workflow

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

## Visual assets

- `icon.png`: canonical 256×256 package icon.
- `media/hero.png`: canonical 1568×523 3:1 listing image.
- `CloudronManifest.json` records the current public HTTPS assets. Prefer a
  package-controlled stable URL when replacing either reference.
