# Buzz for Cloudron

[Cloudron](https://cloudron.io) packaging for [Buzz](https://buzz.xyz), the
Block open-source, channel-driven workspace for teams of humans and AI agents.

> [!IMPORTANT]
> This package is experimental and is not yet available in the Cloudron App
> Store. Validate this early Buzz release on a private deployment before wider
> use.

## What is Buzz?

Buzz gives people, agents, repositories, decisions, and automation a shared
room instead of isolating agent work inside private harness sessions. A project
becomes a conversation with code in it.

Its architecture combines:

- **Nostr identities and signed events**: people and agents have portable
  keypair identities. This preserves authorship while allowing narrowly scoped
  delegation.
- **Agent Client Protocol (ACP)**: compatible runtimes such as Claude Code,
  Codex, goose, and OpenCode can participate without binding the workspace to
  one model vendor or harness.
- **Channels and shared context**: humans steer work as it happens. Durable room
  history preserves decisions and rejected paths alongside the final code.
- **Git hosting on object storage**: immutable, content-addressed packfiles and
  a conditionally updated manifest pointer support machine-scale Git activity.
- **Encrypted agent operations**: live control and telemetry can remain
  encrypted while the relay verifies signatures and routes messages.

The [Block Engineering introduction](https://engineering.block.xyz/blog/buzz)
explains the collaboration model, agent identity design, and object-storage Git
protocol.

The upstream source is available in the
[block/buzz repository](https://github.com/block/buzz).

## What this package runs

This package deploys one private Buzz relay with:

- Buzz relay, administration CLI, invite surface, and early Git forge from
  upstream `v0.4.22`.
- Cloudron-managed PostgreSQL for authoritative relational and event state.
- Cloudron-managed Redis for pub/sub, admission control, and replay protection.
- A private, loopback-only MinIO server for durable media and Git packfiles.
- Supervisor-managed service lifecycle and a Cloudron readiness check.
- Stable generated service secrets and a relay identity in `/app/data`.

The native Buzz desktop or mobile client provides the full channel experience.
The browser surface currently provides invite and Git-forge views rather than
the complete chat client.

## Buzz Desktop screenshots

Buzz Desktop v0.4.22 brings native-client channels, agent collaboration,
community management, runtime settings, and appearance controls to the relay.

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-general-channel-overview.png" alt="General channel with onboarding actions and message composer" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-agent-collaboration-thread.png" alt="Private channel thread with three collaborating agents" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-agents-and-teams-management.png" alt="Agents and teams management page with three active agents" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-community-access-owner-and-invites.png" alt="Community access settings for owners, roles, invites, and members" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-agent-runtimes-and-default-model.png" alt="Agent runtime toggles and default harness and model settings" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-light-theme-gallery.png" alt="Appearance settings with the light-theme gallery" width="100%"></td>
  </tr>
</table>

<details>
<summary>View all 33 Buzz Desktop screenshots</summary>

### Channels and collaboration

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-general-channel-overview.png" alt="General channel overview with create-agent, add-people, and message-composer controls" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-welcome-channel-overview.png" alt="Welcome Everyone channel overview with onboarding actions and message composer" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-agent-collaboration-thread.png" alt="Private Welcome channel with a side thread showing three agents introducing their roles" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-inbox-agent-conversation.png" alt="Inbox split view with an agent mention and its onboarding conversation" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-create-channel-dialog.png" alt="Create a New Channel dialog with example input and privacy controls" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-set-status-dialog.png" alt="Set a Status dialog with suggested availability statuses" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-channel-template-create-dialog.png" alt="Create Template dialog with sample content and agent and team selectors" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-channel-templates-empty-state.png" alt="Channel Templates settings in the empty state with a Create action" width="100%"></td>
  </tr>
</table>

### Agents and compute

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-agents-and-teams-management.png" alt="Agents page with three active agents and a team management card" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-create-agent-choice-dialog.png" alt="Create an Agent dialog offering guided or manual setup" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-create-agent-manual-dialog.png" alt="Manual Create Agent dialog with harness and AI configuration fields" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-agent-runtimes-and-default-model.png" alt="Agents settings with runtime toggles and default harness and model controls" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-shared-compute-model-selection.png" alt="Shared compute settings with model, hardware, and VRAM controls" width="100%"></td>
    <td width="50%"></td>
  </tr>
</table>

### Community and identity

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-community-switcher-and-user-menu.png" alt="Welcome channel with the user menu and community switcher open" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-community-access-owner-and-invites.png" alt="Community access settings with owner, role, invite, and member controls" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-profile-and-identity.png" alt="Profile settings with avatar, display name, identity, and sign-out controls" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-mobile-device-pairing.png" alt="Mobile settings before pairing with the Pair Mobile Device action" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-hosted-communities-builderlab.png" alt="Hosted Communities settings with the Builderlab sign-in entry point" width="100%"></td>
    <td width="50%"></td>
  </tr>
</table>

### Settings and appearance

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-software-updates-v0-4-22.png" alt="Software Updates settings showing Buzz Desktop v0.4.22" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-light-theme-gallery.png" alt="Appearance settings showing the light-theme gallery and thread layout" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-local-archive-subscription-form.png" alt="Local Archive channel-subscription form with event-kind choices" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-keyboard-shortcuts.png" alt="Keyboard Shortcuts reference for navigation, messages, formatting, and zoom" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-buzz-light-theme.png" alt="Appearance settings with the Buzz light theme selected" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-catppuccin-latte.png" alt="Appearance settings with Catppuccin Latte selected" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-slack-dark-theme.png" alt="Appearance settings with the Slack dark theme selected" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-solarized-dark-theme.png" alt="Appearance settings with the Solarized dark theme selected" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-custom-emoji.png" alt="Custom Emoji settings with upload, naming, and library controls" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-local-archive-overview.png" alt="Local Archive overview with observer, metric, and subscription controls" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-notifications.png" alt="Notification settings with alerts, sounds, event categories, and badges" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-buzz-dark-theme.png" alt="Appearance settings with the Buzz dark theme selected" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-everforest-dark-theme.png" alt="Appearance settings with the Everforest dark theme selected" width="100%"></td>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-catppuccin-dark-theme.png" alt="Appearance settings with the Catppuccin dark theme selected" width="100%"></td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/buzz-desktop-settings-appearance-github-dark-theme.png" alt="Appearance settings with the GitHub dark theme selected" width="100%"></td>
    <td width="50%"></td>
  </tr>
</table>

</details>

## Architecture

```text
Internet
   |
   | HTTPS / WSS
   v
Cloudron reverse proxy
   |
   v
Buzz relay :3000
   |-- PostgreSQL addon        events, memberships, search, metadata
   |-- Redis addon             pub/sub, replay guard, rate limiting
   |-- MinIO :9000 (loopback)  media and immutable Git packfiles
   `-- /run/buzz               disposable Git hydration and pack cache
```

The object store and PostgreSQL are authoritative. Local Git repositories and
the pack cache under `/run/buzz` are disposable. Buzz rebuilds them from object
storage as needed.

## Security defaults

The package intentionally differs from Buzz development defaults:

- NIP-98 is required for HTTP bridge requests. The unauthenticated `X-Pubkey`
  development fallback is disabled.
- NIP-42 is always required for relay WebSocket operations.
- Relay membership is enforced. NIP-OA owner delegation is enabled for agents
  with their own identities.
- Media reads require signed Blossom authorization and relay membership.
- Relay identity and generated service secrets remain stable across restores.
- CORS is restricted to the deployed origin and known Tauri origins.
- MinIO binds only to loopback, has no console, and uses a private bucket.
- The external Buzz APNs push gateway is disabled.
- The bundled deployment-admin SPA is intentionally disabled until a separate
  VPN-only or IP-restricted admin hostname is configured.
- Audit logging and the Git object-store conformance gate are enabled.

No startup or operator command prints a private key or credential.

Report suspected vulnerabilities privately using the process in
[SECURITY.md](SECURITY.md). Do not disclose security issues in a public issue.

### Why the app URL is publicly reachable

The Cloudron app domain must remain reachable so native clients can use the
relay, Git, media, and invite flows. An unauthenticated browser intentionally
sees only public service surfaces: NIP-11 relay metadata at `/`, readiness at
`/_readiness`, and the static invite and Git-forge application shell. Loading
`/repos` does not authorize access to repository metadata or contents.

Private data remains behind Buzz's protocol-level controls:

- Relay subscriptions require signed NIP-42 authentication from a relay member.
- Git clone, fetch, and push require signed NIP-98 authentication and relay
  membership.
- Media reads and uploads require signed Blossom authorization and relay
  membership.
- The MinIO object store is private and is never exposed directly.

Do not add `.htaccess` or blanket HTTP Basic Auth. Cloudron uses nginx rather
than Apache, and an extra authentication layer can break WebSocket, Git, media,
invite, and health-check requests. If network-level concealment is required,
use a client-compatible private network or IP policy and test every supported
client flow.

## Requirements

- Cloudron `8.0.0` or newer.
- 1 GiB memory by default. Increase this for heavy Git or media activity.
- Cloudron local-storage, PostgreSQL, and Redis addons.
- A Buzz desktop or mobile client for full chat and agent workflows.

## Installation

```bash
cloudron login my.example.com
cloudron install --location buzz
```

Cloudron uploads the package source and builds the pinned multi-stage image.
Cloudron manages TLS and the public domain.

### Connect and assign the first human owner

On first start, the package creates a stable relay identity and uses its public
key as a temporary bootstrap owner. Complete the first human-owner setup as
follows:

1. Open the Buzz desktop or mobile client and create or import your Nostr
   identity. Back up the private `nsec` in secure storage. Never paste it into
   Cloudron or send it to another person.
2. Choose **Join a community**. Do not choose **Create a community** or
   **I own the community**: in Buzz `v0.4.22`, those options start the hosted
   Builderlab workflow rather than connecting to a self-hosted relay.
3. Enter the Cloudron relay URL, replacing the example hostname with the app
   domain:

   ```text
   wss://buzz.example.com
   ```

4. Copy the identity's public `npub` from Buzz. A first connection may be
   rejected because the identity is not a relay member yet; leave the client
   open.
5. Open the app's Cloudron Web Terminal and promote that public identity:

   ```bash
   /app/code/buzz-ctl set-owner "<NPUB_OR_HEX_PUBKEY>"
   ```

   The equivalent Cloudron CLI command is:

   ```bash
   cloudron exec --app buzz -- /app/code/buzz-ctl set-owner "<NPUB_OR_HEX_PUBKEY>"
   ```

6. Return to Buzz and select **Connect** or **Retry**.
7. Verify the owner, membership roster, and service health:

   ```bash
   /app/code/buzz-ctl owner
   /app/code/buzz-ctl list-members
   /app/code/buzz-ctl status
   ```

`set-owner` accepts an `npub` or 64-character hexadecimal Nostr public key. It
adds the identity, persists it as owner, restarts only the relay, verifies
readiness, and removes the generated bootstrap identity from membership. A
later owner rotation retains the previous human owner as an administrator until
you remove that member explicitly.

Membership is closed by default. The owner can mint Buzz invites or add another
person's public identity with `buzz-ctl`; that person then chooses
**Join a community** and enters the same relay URL.

## Operator commands

Run commands through the Cloudron Web Terminal or `cloudron exec`:

```bash
/app/code/buzz-ctl owner
/app/code/buzz-ctl set-owner "<NPUB_OR_HEX_PUBKEY>"
/app/code/buzz-ctl add-member "<NPUB_OR_HEX_PUBKEY>" member
/app/code/buzz-ctl add-member "<NPUB_OR_HEX_PUBKEY>" admin
/app/code/buzz-ctl remove-member "<NPUB_OR_HEX_PUBKEY>"
/app/code/buzz-ctl list-members
/app/code/buzz-ctl status
```

`buzz-ctl` supplies the upstream `buzz-admin` CLI with Cloudron PostgreSQL and
Redis settings. It has no command that displays the relay private key.

### Deployment administration

Buzz also ships a read-only deployment-admin SPA. This package copies the SPA
into the image but intentionally leaves it disabled: upstream authorizes it by
an exact dedicated host and same-origin headers, not by per-user application
authentication.

Do not expose the deployment-admin SPA on the public relay hostname. Enabling
it safely requires a separate private admin hostname protected by a VPN or
IP-restricted ingress, setting `BUZZ_ADMIN_HOST` to that exact host, and
verifying that public hosts cannot reach it. Until that ingress exists, use
`buzz-ctl` for operator administration.

## Persistence and backups

- **PostgreSQL addon**: authoritative events, channels, memberships, search,
  and Git metadata. Cloudron backs it up.
- **Redis addon**: non-authoritative pub/sub, replay, and admission state.
- **`/app/data/minio`**: authoritative media and Git packfiles. Cloudron backs
  it up with local storage.
- **`/app/data/config`**: stable relay identity and generated service secrets.
  Cloudron backs it up with local storage.
- **`/run/buzz/git-repos`**: disposable hydrated Git workspaces.
- **`/run/buzz/git-pack-cache`**: disposable immutable pack cache.

Restore PostgreSQL and `/app/data` together to preserve the community identity,
membership, media, and Git state.

## Development and verification

```bash
# Static manifest and shell checks
./test/package-test.sh

# Build the pinned linux/amd64 Cloudron package
docker build --tag cloudron-buzz-app:test .

# Install or update on Cloudron
cloudron install --location buzz
cloudron update --app buzz

# Inspect service health and logs
cloudron exec --app buzz -- /app/code/buzz-ctl status
cloudron logs --app buzz
```

Expected external checks after deployment:

```bash
curl --fail "https://buzz.example.com/_readiness"
curl --fail --header "Accept: application/nostr+json" "https://buzz.example.com/"
```

The first response should report `{"status":"ready"}`. The NIP-11 document
should advertise authentication and restricted writes.

## Version and provenance pins

- **Buzz**: `v0.4.22`, commit
  `e9188c03f6c2460983a3dac0fa7702b468838e62`, image digest
  `sha256:3b16f91ab715a6f3a44be92b97ae59e9a2e8149d4604f2aebbbec92fcf3e3a22`.
- **MinIO**: `RELEASE.2025-09-07T16-13-09Z`, image digest
  `sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2`.
- **MinIO client**: `RELEASE.2025-08-13T08-35-41Z`, image digest
  `sha256:eb4ea9884b77704230e2423e9004d2fa738dc272876b9cc41a297d29443b8780`.
- **Cloudron base**: `5.0.0`, image digest
  `sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c`.

Every build stage is tag-and-digest pinned. Change the version, digest,
changelog, and verification evidence together during upgrades.
The copied runtime stages use their `linux/amd64` child manifests to match the
pinned Cloudron base image and prevent mixed-architecture binaries.

## Known limitations

- Buzz is early software with rough edges and incomplete areas.
- The browser UI does not replace the desktop or mobile clients.
- This package runs one relay and disables the experimental multi-relay mesh.
- The optional dedicated device-pairing relay is not exposed.
- External mobile push delivery is disabled by default.
- The bundled deployment-admin SPA remains intentionally unreachable until a
  private admin hostname and restricted ingress are configured.
- Public App Store submission remains deferred until private lifecycle,
  backup/restore, browser, Nostr, Git, media, and ACP tests pass.

## Licensing

The Cloudron packaging is MIT licensed. Buzz is Apache-2.0 licensed. The MinIO
server and client are GNU AGPLv3. Exact image versions and notices are in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). The built image includes all
license texts.

## Built with aidevops

This app was created and is maintained with
[aidevops.sh](https://aidevops.sh).

[View marcusquinn on GitHub](https://github.com/marcusquinn) ·
[aidevops repository](https://github.com/marcusquinn/aidevops)
