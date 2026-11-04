#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

TEST_DIR=""
TEST_DIR=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
readonly TEST_DIR
readonly ROOT_DIR="${TEST_DIR%/*}"
readonly CATALOG_BASELINE="test/published-catalog-manifests.sha256"

fail() {
	local message="$1"
	printf "FAIL: %s\n" "$message" >&2
	return 1
}

pass() {
	local message="$1"
	printf "PASS: %s\n" "$message"
	return 0
}

assert_file() {
	local relative_path="$1"
	if [[ ! -f "${ROOT_DIR}/${relative_path}" ]]; then
		fail "Missing required file: ${relative_path}" || return 1
	fi
	return 0
}

assert_contains() {
	local relative_path="$1"
	local expected_text="$2"
	if ! grep -Fq -- "$expected_text" "${ROOT_DIR}/${relative_path}"; then
		fail "${relative_path} does not contain expected text: ${expected_text}" || return 1
	fi
	return 0
}

assert_precedes() {
	local relative_path="$1"
	local first="$2"
	local second="$3"
	local first_line=""
	local second_line=""
	first_line="$(grep -nF -- "$first" "${ROOT_DIR}/${relative_path}" | cut -d: -f1)"
	second_line="$(grep -nF -- "$second" "${ROOT_DIR}/${relative_path}" | cut -d: -f1)"
	[[ -n "$first_line" && -n "$second_line" && "$first_line" -lt "$second_line" ]] || fail "${relative_path} must place ${first} before ${second}" || return 1
	return 0
}

catalog_manifest_digest() {
	local version="$1"
	jq -cS --arg version "$version" '.versions[$version].manifest' "${ROOT_DIR}/CloudronVersions.json" | shasum -a 256 | cut -d ' ' -f1
	return 0
}

# An unrecorded current-version entry must be exactly what the publisher builds:
# the source manifest, its CHANGELOG section, and an immutable package image.
assert_current_catalog_entry() {
	local version="$1"
	local changelog_section=""

	changelog_section=$(awk -v header="[${version}]" '$0 == header {found=1; next} found && /^$/ {exit} found {print}' "${ROOT_DIR}/CHANGELOG")
	jq -e --arg version "$version" --arg changelog "${changelog_section}"$'\n' --slurpfile source "${ROOT_DIR}/CloudronManifest.json" '
		.versions[$version].manifest as $entry
		| ($entry.dockerImage | test("^ghcr\\.io/marcusquinn/cloudron-buzz-app@sha256:[0-9a-f]{64}$"))
		and $entry.changelog == $changelog
		and ($entry | del(.dockerImage, .changelog)) == ($source[0] | del(.changelog))
	' "${ROOT_DIR}/CloudronVersions.json" >/dev/null || fail "Unrecorded catalog entry ${version} does not match CloudronManifest.json, CHANGELOG and an immutable package image" || return 1
	return 0
}

# Published catalog entries are append-only. The baseline holds one
# "<version> <sha256 of the canonical manifest>" line per published version and
# is checked against the checked-out tree, not the merge base. The managed
# publisher appends the current manifest version to the catalog on main without
# touching this file, so only that version may be unrecorded, and it must match
# the source manifest; the next package release PR must record it.
assert_published_catalog_baseline() {
	local baseline="${ROOT_DIR}/${CATALOG_BASELINE}"
	local catalog="${ROOT_DIR}/CloudronVersions.json"
	local current_version=""
	local version=""
	local expected_digest=""
	local missing=""

	if grep -Evq '^[0-9]+\.[0-9]+\.[0-9]+ [0-9a-f]{64}$' "$baseline"; then
		fail "${CATALOG_BASELINE} lines must be '<version> <sha256>'" || return 1
	fi
	if [[ -n "$(cut -d ' ' -f1 "$baseline" | sort | uniq -d)" ]]; then
		fail "${CATALOG_BASELINE} records a version more than once" || return 1
	fi
	while read -r version expected_digest; do
		jq -e --arg version "$version" '.versions | has($version)' "$catalog" >/dev/null || fail "Recorded catalog version ${version} was removed; published entries are append-only" || return 1
		[[ "$(catalog_manifest_digest "$version")" == "$expected_digest" ]] || fail "Published catalog manifest ${version} changed; add a new version instead of mutating a published entry" || return 1
	done <"$baseline"
	current_version=$(jq -r '.version' "${ROOT_DIR}/CloudronManifest.json")
	while read -r version; do
		if [[ "$version" == "$current_version" ]]; then
			grep -q "^${version//./\\.} " "$baseline" || assert_current_catalog_entry "$version" || return 1
			continue
		fi
		grep -q "^${version//./\\.} " "$baseline" || missing="${missing}${version} $(catalog_manifest_digest "$version")"$'\n'
	done < <(jq -r '.versions | to_entries[] | select(.value.publishState == "published") | .key' "$catalog")
	if [[ -n "$missing" ]]; then
		printf "Append these lines to %s:\n%s" "$CATALOG_BASELINE" "$missing" >&2
		fail "Published catalog entries are not recorded in ${CATALOG_BASELINE}" || return 1
	fi
	return 0
}

check_release_workflows() {
	assert_contains .agents/AGENTS.md 'wss://<app-host>' || return 1
	assert_contains .agents/AGENTS.md "public \`npub\` or hexadecimal public key" || return 1
	assert_contains .agents/AGENTS.md "transmit an \`nsec\` or any other private key" || return 1
	assert_contains .agents/AGENTS.md '/app/code/buzz-ctl set-owner <NPUB_OR_HEX_PUBKEY>' || return 1
	assert_contains CloudronManifest.json 'The initial **Not a member yet** message is expected' || return 1
	assert_contains CloudronManifest.json 'If the Web Terminal stays on **Connecting**' || return 1
	assert_contains CloudronManifest.json "cloudron exec --app \$CLOUDRON-APP-FQDN -- /app/code/buzz-ctl set-owner <NPUB_OR_HEX_PUBKEY>" || return 1
	assert_contains CloudronManifest.json 'Never put an nsec or other private key in either command' || return 1
	assert_contains README.md 'cloudron exec --app buzz.example.com -- /app/code/buzz-ctl set-owner "<NPUB_OR_HEX_PUBKEY>"' || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "tags:" || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "- 'v*'" || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "uses: marcusquinn/aidevops/.github/workflows/cloudron-package-release-reusable.yml@22a6b4b29087ce2fcf3857596a40ff7b2c436482" || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "aidevops_ref: 22a6b4b29087ce2fcf3857596a40ff7b2c436482" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "branches: [main]" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "pull_request:" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "attestations: write" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "id-token: write" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "packages: write" || return 1
	# Publication and attestation internals belong to the pinned reusable workflow.
	assert_contains .github/workflows/cloudron-catalog-publish.yml "uses: marcusquinn/aidevops/.github/workflows/cloudron-catalog-publish-reusable.yml@4366037537f8a9aaf7f738a37465a6b1433dd6d5" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "aidevops_ref: 4366037537f8a9aaf7f738a37465a6b1433dd6d5" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "image_repository: ghcr.io/marcusquinn/cloudron-buzz-app" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "cli_version: '8.2.6'" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "cli_integrity: sha512-LHd+4u6pJxDtHX1JuVuWqrUuTbkDu+iH4jjNWW6JgB4+iDLusp08rpt6gifTFPbQjbCZHhnD8LbAGzM1NzDCXw==" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "CLOUDRON_RELEASE_PAT: \${{ secrets.CLOUDRON_RELEASE_PAT }}" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "package_checks: |" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "./test/package-test.sh" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml './test/verify-buzz-image.sh' || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "docker build --platform linux/amd64 --tag cloudron-buzz-app:test ." || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "./test/pairing-proxy-test.sh cloudron-buzz-app:test" || return 1
	assert_precedes .github/workflows/cloudron-catalog-publish.yml "docker build --platform" "./test/pairing-proxy-test.sh" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "./test/storage-guard-test.sh cloudron-buzz-app:test" || return 1
	assert_precedes .github/workflows/cloudron-catalog-publish.yml "docker build --platform" "./test/storage-guard-test.sh" || return 1
	[[ "$(grep -Fc 'secrets.CLOUDRON_RELEASE_PAT' "${ROOT_DIR}/.github/workflows/cloudron-catalog-publish.yml")" -eq 1 ]] || fail "Release PAT must be forwarded exactly once to the reusable publisher" || return 1
	assert_contains scripts/publish-cloudron-catalog.sh "cloudron versions add --image \"\$image_ref\" --state testing" || return 1
	assert_contains scripts/publish-cloudron-catalog.sh "cloudron versions update --image \"\$image_ref\" --version \"\$package_version\" --state published" || return 1
	pass "Managed release workflow and private-community onboarding"
	return 0
}

main() {
	local required_file=""
	local shell_script=""

	for required_file in CloudronManifest.json Dockerfile start.sh run-rustfs.sh storage-setup.sh run-pairing-relay.sh run-relay.sh buzz-ctl nginx.conf supervisord.conf README.md SECURITY.md CHANGELOG.md CHANGELOG CloudronVersions.json PUBLISHING.md DESIGN.md media/hero.png LICENSE LICENSES/Apache-2.0.txt THIRD_PARTY_NOTICES.md icon.png scripts/publish-cloudron-catalog.sh test/published-catalog-manifests.sha256 test/pairing-proxy-test.sh test/storage-guard-test.sh test/publish-catalog-test.sh test/verify-buzz-image.sh .agents/AGENTS.md .github/workflows/cloudron-catalog-publish.yml .github/workflows/cloudron-package-release.yml; do
		assert_file "$required_file" || return 1
	done

	jq --exit-status ".manifestVersion == 2 and .httpPort == 3000 and .healthCheckPath == \"/_readiness\" and .version == \"0.1.27\" and .upstreamVersion == \"0.5.27\" and .minBoxVersion == \"10.0.0\" and .iconUrl != \"\" and .packagerName != \"\" and .packagerUrl == \"https://github.com/marcusquinn/cloudron-buzz-app\" and .packageUrl == \"https://github.com/marcusquinn/cloudron-buzz-app\" and (.mediaLinks | length) > 0 and .changelog == \"file://CHANGELOG\" and (.addons | has(\"localstorage\") and has(\"postgresql\") and has(\"redis\"))" "${ROOT_DIR}/CloudronManifest.json" >/dev/null || {
		fail "CloudronManifest.json does not match the package contract" || return 1
	}
	pass "Cloudron manifest contract"
	jq --exit-status '.stable == true and (.versions | type == "object")' "${ROOT_DIR}/CloudronVersions.json" >/dev/null || {
		fail "CloudronVersions.json does not match the catalog contract" || return 1
	}
	jq --exit-status '[.versions[].manifest | select(has("packageUrl")) | (.minBoxVersion | split(".") | .[0] | tonumber) >= 10] | all' "${ROOT_DIR}/CloudronVersions.json" >/dev/null || {
		fail "Catalog entries with packageUrl must require Cloudron 10.0.0 or later" || return 1
	}
	assert_contains CHANGELOG '[0.1.27]' || return 1
	assert_contains CHANGELOG.md '[0.1.27]' || return 1
	assert_contains PUBLISHING.md 'cloudron versions update --image=<DIGEST> --version=<VERSION> --state=published' || return 1
	jq -e '.versions["0.1.4"].publishState == "published"' "${ROOT_DIR}/CloudronVersions.json" >/dev/null || fail "Published catalog state contract failed" || return 1
	assert_published_catalog_baseline || return 1
	pass "Cloudron community publishing baseline"
	assert_contains CloudronManifest.json "Join a community" || return 1
	assert_contains CloudronManifest.json "hosted Builderlab workflow" || return 1
	assert_contains README.md "blanket HTTP Basic Auth" || return 1
	assert_contains README.md "https://github.com/block/buzz" || return 1
	assert_contains README.md "intentionally leaves it disabled" || return 1
	assert_contains README.md "https://aidevops.sh" || return 1
	assert_contains README.md "https://github.com/marcusquinn/aidevops" || return 1
	assert_contains README.md "## Buzz Desktop screenshots" || return 1
	assert_contains README.md "docs/screenshots/buzz-desktop-general-channel-overview.png" || return 1
	assert_contains README.md "docs/screenshots/buzz-desktop-agent-collaboration-thread.png" || return 1
	assert_contains README.md "[SECURITY.md](SECURITY.md)" || return 1
	assert_contains CloudronManifest.json "wss://\$CLOUDRON-APP-FQDN" || return 1
	assert_contains SECURITY.md "GitHub's private vulnerability reporting" || return 1
	assert_contains SECURITY.md "| \`0.1.27\` | \`0.5.27\` | Yes |" || return 1

	if git -C "$ROOT_DIR" ls-files -s | grep -Eq '^120000 '; then
		fail "Published source must not contain tracked symlinks" || return 1
	fi
	if git -C "$ROOT_DIR" grep -IEn '(/Users/[^/[:space:]]+/|/home/[^/[:space:]]+/)' -- . ':!test/package-test.sh'; then
		fail "Published source must not contain absolute user home-directory paths" || return 1
	fi
	pass "Public source path safety"

	check_release_workflows || return 1

	assert_contains Dockerfile "FROM --platform=linux/amd64 ghcr.io/block/buzz:sha-af5bb0a@sha256:a212517165be1b34de022345a109f93eab2575ed08ed48439db592ce703eff33 AS buzz" || return 1
	assert_contains THIRD_PARTY_NOTICES.md "ghcr.io/block/buzz:sha-af5bb0a@sha256:a212517165be1b34de022345a109f93eab2575ed08ed48439db592ce703eff33" || return 1
	assert_contains THIRD_PARTY_NOTICES.md "Linux/amd64 manifest: \`sha256:dd998c7499d92cffbf5a71609a5231bd88d3ca0e987f03d1324bd759db57ccb7\`" || return 1
	assert_contains THIRD_PARTY_NOTICES.md 'Provenance: independently registry-inspected; the OCI revision label matches' || return 1
	assert_contains THIRD_PARTY_NOTICES.md "\`desktop-v0.5.27\` release-only tag commit." || return 1
	assert_contains THIRD_PARTY_NOTICES.md "- Release commit: \`7a2fb3cc2d401e91e67d9819741d9025278cbec0\`" || return 1
	assert_contains THIRD_PARTY_NOTICES.md "- Image revision: \`af5bb0af488784c3707e99c87e0675a729711a6e\`" || return 1
	assert_contains README.md './test/verify-buzz-image.sh' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_RELEASE="desktop-v0.5.27"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_RELEASE_REVISION="7a2fb3cc2d401e91e67d9819741d9025278cbec0"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_REVISION="af5bb0af488784c3707e99c87e0675a729711a6e"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_IMAGE="ghcr.io/block/buzz:sha-af5bb0a"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_INDEX_DIGEST="sha256:a212517165be1b34de022345a109f93eab2575ed08ed48439db592ce703eff33"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_AMD64_DIGEST="sha256:dd998c7499d92cffbf5a71609a5231bd88d3ca0e987f03d1324bd759db57ccb7"' || return 1
	assert_contains test/verify-buzz-image.sh "docker buildx imagetools inspect" || return 1
	assert_contains test/verify-buzz-image.sh 'org.opencontainers.image.revision' || return 1
	# GH#92: the Silo/MinIO server and mcli client are no longer shipped.
	if grep -Eiq 'silo|mcli|minio' "${ROOT_DIR}/Dockerfile" "${ROOT_DIR}/supervisord.conf" "${ROOT_DIR}/run-relay.sh"; then
		fail "Silo/MinIO components must not remain in the image or runtime" || return 1
	fi
	if [[ -e "${ROOT_DIR}/run-minio.sh" || -e "${ROOT_DIR}/storage-migrate.sh" ]]; then
		fail "Legacy Silo launcher and migration scripts must be removed" || return 1
	fi
	assert_contains Dockerfile 'LABEL org.opencontainers.image.licenses="MIT AND Apache-2.0"' || return 1
	assert_contains Dockerfile "cloudron/base:6.0.1@sha256:7b1e729960c3ca312d26e886917ba89483241bba0219ff292858e10d9d5768ee" || return 1
	if grep -Eq "^FROM[[:space:]]+([^[:space:]@-][^[:space:]@]*|--platform=[^[:space:]]+[[:space:]]+[^[:space:]@]+)(:latest)?([[:space:]]|$)" "${ROOT_DIR}/Dockerfile"; then
		fail "Every Docker stage must be tag-and-digest pinned" || return 1
	fi
	pass "Container provenance pins"

	for shell_script in start.sh run-rustfs.sh storage-setup.sh run-pairing-relay.sh run-relay.sh buzz-ctl scripts/publish-cloudron-catalog.sh test/package-test.sh test/pairing-proxy-test.sh test/storage-guard-test.sh test/publish-catalog-test.sh test/verify-buzz-image.sh; do
		bash -n "${ROOT_DIR}/${shell_script}"
		shellcheck "${ROOT_DIR}/${shell_script}"
	done
	pass "Bash syntax and ShellCheck"
	"${ROOT_DIR}/test/publish-catalog-test.sh" || return 1
	pass "Cloudron catalog publication safeguards"

	assert_contains run-relay.sh "BUZZ_REQUIRE_AUTH_TOKEN=\"\$FEATURE_ENABLED\"" || return 1
	assert_contains run-relay.sh "BUZZ_REQUIRE_RELAY_MEMBERSHIP=\"\$FEATURE_ENABLED\"" || return 1
	assert_contains run-relay.sh "BUZZ_PUSH_GATEWAY_DELIVERY_URL=\"\"" || return 1
	assert_contains run-relay.sh "BUZZ_GIT_REPO_PATH=\"\${RUN_DIR}/git-repos\"" || return 1
	assert_contains run-relay.sh "BUZZ_PAIRING_RELAY_URL=\"wss://\${CLOUDRON_APP_DOMAIN}/pair\"" || return 1
	assert_contains run-relay.sh 'BUZZ_BIND_ADDR="127.0.0.1:3001"' || return 1
	assert_contains run-pairing-relay.sh 'BUZZ_PAIR_RELAY_BIND_ADDR="127.0.0.1:5000"' || return 1
	assert_contains nginx.conf 'location = /pair' || return 1
	assert_contains nginx.conf 'proxy_pass http://buzz_pairing_relay;' || return 1
	assert_contains nginx.conf 'pairing_client_address>[0-9A-Fa-f:.]+' || return 1
	assert_contains nginx.conf 'limit_conn pairing_per_client 4;' || return 1
	assert_contains nginx.conf 'proxy_request_buffering off;' || return 1
	assert_contains supervisord.conf '[program:buzz-pairing-relay]' || return 1
	assert_contains supervisord.conf '[program:nginx]' || return 1
	pass "Production security defaults"
	assert_contains Dockerfile 'ARG RUSTFS_SHA256=a834096dafa1f1a55825a2cdaf49d006a193978d344f2d508c2be475133738a3' || return 1
	assert_contains Dockerfile 'sha256sum -c -' || return 1
	assert_contains run-rustfs.sh 'RUSTFS_ADDRESS=127.0.0.1:9100' || return 1
	assert_contains run-rustfs.sh 'RUSTFS_CONSOLE_ENABLE=false' || return 1
	assert_contains run-rustfs.sh 'RUSTFS_SECRET_KEY_FILE=/app/data/config/rustfs-secret-key' || return 1
	assert_contains storage-setup.sh 'readonly LAST_DUAL_STORE_RELEASE=0.1.26' || return 1
	assert_contains storage-setup.sh "failed) refuse_unmigrated \"\$state\" || return 1 ;;" || return 1
	assert_contains storage-setup.sh 'flock -n 9' || return 1
	assert_contains run-relay.sh 'readonly STORAGE_ENDPOINT="http://127.0.0.1:9100"' || return 1
	assert_contains run-relay.sh "--config \"\$S3_CURL_CONFIG\" --aws-sigv4 \"aws:amz:us-east-1:s3\"" || return 1
	assert_contains run-relay.sh 'Buzz bucket must refuse anonymous access' || return 1
	assert_contains buzz-ctl "storage-purge-legacy) storage_purge_legacy \"\$first_argument\" || return 1 ;;" || return 1
	assert_contains buzz-ctl "if [[ \"\$confirmation\" != --confirm ]]; then" || return 1
	assert_contains buzz-ctl "if [[ \"\$state\" != migrated && \"\$state\" != not-needed ]]; then" || return 1
	if grep -Eq 'rm -rf' "${ROOT_DIR}/start.sh" "${ROOT_DIR}/storage-setup.sh"; then
		fail "Startup must never delete legacy storage automatically" || return 1
	fi
	pass "RustFS-only storage contract"

	if grep -Eq "printf.*(PRIVATE_KEY|SECRET_KEY|PASSWORD)|echo.*(PRIVATE_KEY|SECRET_KEY|PASSWORD)" "${ROOT_DIR}/start.sh" "${ROOT_DIR}/storage-setup.sh" "${ROOT_DIR}/run-pairing-relay.sh" "${ROOT_DIR}/run-relay.sh" "${ROOT_DIR}/buzz-ctl"; then
		fail "A runtime script may print secret material" || return 1
	fi
	pass "No obvious secret disclosure"
	return 0
}

main "$@"
