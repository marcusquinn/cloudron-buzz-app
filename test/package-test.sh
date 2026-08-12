#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

TEST_DIR=""
TEST_DIR=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
readonly TEST_DIR
readonly ROOT_DIR="${TEST_DIR%/*}"

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

check_release_workflows() {
	assert_contains .agents/AGENTS.md 'wss://<app-host>' || return 1
	assert_contains .agents/AGENTS.md "public \`npub\` or hexadecimal public key" || return 1
	assert_contains .agents/AGENTS.md "transmit an \`nsec\` or any other private key" || return 1
	assert_contains .agents/AGENTS.md '/app/code/buzz-ctl set-owner <NPUB_OR_HEX_PUBKEY>' || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "tags:" || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "- 'v*'" || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "uses: marcusquinn/aidevops/.github/workflows/cloudron-package-release-reusable.yml@22a6b4b29087ce2fcf3857596a40ff7b2c436482" || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "aidevops_ref: 22a6b4b29087ce2fcf3857596a40ff7b2c436482" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "branches:" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "- main" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "attestations: write" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "id-token: write" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "packages: write" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "pull-requests: read" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "github.ref == 'refs/heads/main'" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "persist-credentials: false" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "GH_TOKEN: \${{ secrets.CLOUDRON_RELEASE_PAT }}" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "CLOUDRON_RELEASE_PAT is not configured for this repository" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "CLOUDRON_CLI_INTEGRITY: sha512-LHd+4u6pJxDtHX1JuVuWqrUuTbkDu+iH4jjNWW6JgB4+iDLusp08rpt6gifTFPbQjbCZHhnD8LbAGzM1NzDCXw==" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "cloudron@\${CLOUDRON_CLI_VERSION}" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml 'author_association == "OWNER"' || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "./scripts/publish-cloudron-catalog.sh \"\$IMAGE_REF\"" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "./test/pairing-proxy-test.sh \"\$image_tag\"" || return 1
	assert_precedes .github/workflows/cloudron-catalog-publish.yml "./test/pairing-proxy-test.sh \"\$image_tag\"" "docker push \"\$image_tag\"" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "uses: actions/attest-build-provenance@e8998f949152b193b063cb0ec769d69d929409be # v2.4.0" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "subject-name: \${{ env.IMAGE_REPOSITORY }}" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "subject-digest: \${{ steps.image.outputs.digest }}" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "push-to-registry: true" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "subject-path: CloudronVersions.json" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "ATTESTATION_BUNDLE: \${{ steps.image-attestation.outputs.bundle-path }}" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "ATTESTATION_BUNDLE: \${{ steps.catalog-attestation.outputs.bundle-path }}" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "gh attestation verify \"oci://\${IMAGE_REPOSITORY}@\${IMAGE_DIGEST}\"" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "gh attestation verify CloudronVersions.json" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "--repo marcusquinn/cloudron-buzz-app" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "--signer-workflow marcusquinn/cloudron-buzz-app/.github/workflows/cloudron-catalog-publish.yml" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "--source-ref refs/heads/main" || return 1
	assert_precedes .github/workflows/cloudron-catalog-publish.yml "Generate and validate the published catalog entry" "Attest Cloudron catalog provenance" || return 1
	if grep -A 4 -F -- "- name: Attest Cloudron catalog provenance" "${ROOT_DIR}/.github/workflows/cloudron-catalog-publish.yml" | grep -Fq "if:"; then
		fail "Catalog attestation must run when publication is already complete" || return 1
	fi
	assert_contains .github/workflows/cloudron-catalog-publish.yml "gh auth setup-git" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml "chore(release): publish Buzz catalog \${VERSION} [skip ci]" || return 1
	assert_precedes .github/workflows/cloudron-catalog-publish.yml "git add CloudronVersions.json" "gh auth setup-git" || return 1
	assert_precedes .github/workflows/cloudron-catalog-publish.yml "gh auth setup-git" "git push --atomic" || return 1
	assert_precedes .github/workflows/cloudron-catalog-publish.yml "git push --atomic" "- name: Create GitHub release" || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml 'git push --atomic' || return 1
	assert_contains .github/workflows/cloudron-catalog-publish.yml 'gh release create' || return 1
	[[ "$(grep -Fc 'secrets.CLOUDRON_RELEASE_PAT' "${ROOT_DIR}/.github/workflows/cloudron-catalog-publish.yml")" -eq 1 ]] || fail "Release PAT must be exposed to exactly one publication step" || return 1
	assert_contains scripts/publish-cloudron-catalog.sh "cloudron versions add --image \"\$image_ref\" --state testing" || return 1
	assert_contains scripts/publish-cloudron-catalog.sh "cloudron versions update --image \"\$image_ref\" --version \"\$package_version\" --state published" || return 1
	pass "Managed release workflow and private-community onboarding"
	return 0
}

main() {
	local required_file=""
	local shell_script=""

	for required_file in CloudronManifest.json Dockerfile start.sh run-minio.sh run-pairing-relay.sh run-relay.sh buzz-ctl nginx.conf supervisord.conf README.md SECURITY.md CHANGELOG.md CHANGELOG CloudronVersions.json PUBLISHING.md DESIGN.md media/hero.png LICENSE LICENSES/Apache-2.0.txt THIRD_PARTY_NOTICES.md icon.png scripts/publish-cloudron-catalog.sh test/pairing-proxy-test.sh test/publish-catalog-test.sh test/verify-buzz-image.sh .agents/AGENTS.md .github/workflows/cloudron-catalog-publish.yml .github/workflows/cloudron-package-release.yml; do
		assert_file "$required_file" || return 1
	done

	jq --exit-status ".manifestVersion == 2 and .httpPort == 3000 and .healthCheckPath == \"/_readiness\" and .version == \"0.1.15\" and .upstreamVersion == \"0.5.10\" and .minBoxVersion == \"9.1.0\" and .iconUrl != \"\" and .packagerName != \"\" and .packagerUrl == \"https://github.com/marcusquinn\" and (has(\"packageUrl\") | not) and (.mediaLinks | length) > 0 and .changelog == \"file://CHANGELOG\" and (.addons | has(\"localstorage\") and has(\"postgresql\") and has(\"redis\"))" "${ROOT_DIR}/CloudronManifest.json" >/dev/null || {
		fail "CloudronManifest.json does not match the package contract" || return 1
	}
	pass "Cloudron manifest contract"
	jq --exit-status '.stable == true and (.versions | type == "object")' "${ROOT_DIR}/CloudronVersions.json" >/dev/null || {
		fail "CloudronVersions.json does not match the catalog contract" || return 1
	}
	jq --exit-status '[.versions[].manifest | has("packageUrl")] | all(. == false)' "${ROOT_DIR}/CloudronVersions.json" >/dev/null || {
		fail "Historical catalog entries must remain parseable by Cloudron 9.1 and 9.2" || return 1
	}
	assert_contains CHANGELOG '[0.1.15]' || return 1
	assert_contains CHANGELOG.md '[0.1.15]' || return 1
	assert_contains PUBLISHING.md 'cloudron versions update --image=<DIGEST> --version=<VERSION> --state=published' || return 1
	jq -e '.versions["0.1.4"].publishState == "published"' "${ROOT_DIR}/CloudronVersions.json" >/dev/null || fail "Published catalog state contract failed" || return 1
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
	assert_contains SECURITY.md "| \`0.1.15\` | \`0.5.10\` | Yes |" || return 1

	if git -C "$ROOT_DIR" ls-files -s | grep -Eq '^120000 '; then
		fail "Published source must not contain tracked symlinks" || return 1
	fi
	if git -C "$ROOT_DIR" grep -IEn '(/Users/[^/[:space:]]+/|/home/[^/[:space:]]+/)' -- . ':!test/package-test.sh'; then
		fail "Published source must not contain absolute user home-directory paths" || return 1
	fi
	pass "Public source path safety"

	check_release_workflows || return 1

	assert_contains Dockerfile "FROM --platform=linux/amd64 ghcr.io/block/buzz:sha-f359301@sha256:f3037fb09ec380bde34726256d3b119102bbd6bc48f4354f08a67f30c58fd50d AS buzz" || return 1
	assert_contains THIRD_PARTY_NOTICES.md "ghcr.io/block/buzz:sha-f359301@sha256:f3037fb09ec380bde34726256d3b119102bbd6bc48f4354f08a67f30c58fd50d" || return 1
	assert_contains THIRD_PARTY_NOTICES.md "Linux/amd64 manifest: \`sha256:2c71041615bced7b57315ddfe9242438aafdace105355af7812a1468633ac418\`" || return 1
	assert_contains THIRD_PARTY_NOTICES.md 'Provenance: independently registry-inspected; the OCI revision label matches' || return 1
	assert_contains THIRD_PARTY_NOTICES.md "\`desktop-v0.5.10\` release-only tag commit." || return 1
	assert_contains README.md './test/verify-buzz-image.sh' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_RELEASE="desktop-v0.5.10"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_RELEASE_REVISION="1fb49103002e898607a7f6fd554cb51e94d92e08"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_REVISION="f35930104bcbdb1332ff13735214ecb9fce1fc7b"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_IMAGE="ghcr.io/block/buzz:sha-f359301"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_INDEX_DIGEST="sha256:f3037fb09ec380bde34726256d3b119102bbd6bc48f4354f08a67f30c58fd50d"' || return 1
	assert_contains test/verify-buzz-image.sh 'readonly BUZZ_AMD64_DIGEST="sha256:2c71041615bced7b57315ddfe9242438aafdace105355af7812a1468633ac418"' || return 1
	assert_contains test/verify-buzz-image.sh "docker buildx imagetools inspect" || return 1
	assert_contains test/verify-buzz-image.sh 'org.opencontainers.image.revision' || return 1
	assert_contains Dockerfile "minio/minio:RELEASE.2025-09-07T16-13-09Z@sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2" || return 1
	assert_contains Dockerfile "minio/mc:RELEASE.2025-08-13T08-35-41Z@sha256:eb4ea9884b77704230e2423e9004d2fa738dc272876b9cc41a297d29443b8780" || return 1
	assert_contains Dockerfile "cloudron/base:5.1.0@sha256:1c0666c9abe9e2090d33686826d4e97769b799124573118d41e0d7485135748e" || return 1
	if grep -Eq "^FROM[[:space:]]+([^[:space:]@-][^[:space:]@]*|--platform=[^[:space:]]+[[:space:]]+[^[:space:]@]+)(:latest)?([[:space:]]|$)" "${ROOT_DIR}/Dockerfile"; then
		fail "Every Docker stage must be tag-and-digest pinned" || return 1
	fi
	pass "Container provenance pins"

	for shell_script in start.sh run-minio.sh run-pairing-relay.sh run-relay.sh buzz-ctl scripts/publish-cloudron-catalog.sh test/package-test.sh test/pairing-proxy-test.sh test/publish-catalog-test.sh test/verify-buzz-image.sh; do
		bash -n "${ROOT_DIR}/${shell_script}"
		shellcheck "${ROOT_DIR}/${shell_script}"
	done
	pass "Bash syntax and ShellCheck"
	"${ROOT_DIR}/test/publish-catalog-test.sh" || return 1
	pass "Cloudron catalog publication safeguards"

	assert_contains run-relay.sh "BUZZ_REQUIRE_AUTH_TOKEN=\"\$FEATURE_ENABLED\"" || return 1
	assert_contains run-relay.sh "BUZZ_REQUIRE_RELAY_MEMBERSHIP=\"\$FEATURE_ENABLED\"" || return 1
	assert_contains run-relay.sh "BUZZ_REQUIRE_MEDIA_GET_AUTH=\"\$FEATURE_ENABLED\"" || return 1
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

	if grep -Eq "printf.*(PRIVATE_KEY|SECRET_KEY|PASSWORD)|echo.*(PRIVATE_KEY|SECRET_KEY|PASSWORD)" "${ROOT_DIR}/start.sh" "${ROOT_DIR}/run-minio.sh" "${ROOT_DIR}/run-pairing-relay.sh" "${ROOT_DIR}/run-relay.sh" "${ROOT_DIR}/buzz-ctl"; then
		fail "A runtime script may print secret material" || return 1
	fi
	pass "No obvious secret disclosure"
	return 0
}

main "$@"
