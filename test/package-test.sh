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

main() {
	local required_file=""
	local shell_script=""

	for required_file in CloudronManifest.json Dockerfile start.sh run-minio.sh run-relay.sh buzz-ctl supervisord.conf README.md SECURITY.md CHANGELOG.md CHANGELOG CloudronVersions.json PUBLISHING.md DESIGN.md media/hero.png LICENSE LICENSES/Apache-2.0.txt THIRD_PARTY_NOTICES.md icon.png .agents/AGENTS.md .github/workflows/cloudron-package-release.yml; do
		assert_file "$required_file" || return 1
	done

	jq --exit-status ".manifestVersion == 2 and .httpPort == 3000 and .healthCheckPath == \"/_readiness\" and .version == \"0.1.3\" and .upstreamVersion == \"0.4.24\" and .minBoxVersion == \"9.1.0\" and .iconUrl != \"\" and .packagerName != \"\" and .packagerUrl != \"\" and (.mediaLinks | length) > 0 and .changelog == \"file://CHANGELOG\" and (.addons | has(\"localstorage\") and has(\"postgresql\") and has(\"redis\"))" "${ROOT_DIR}/CloudronManifest.json" >/dev/null || {
		fail "CloudronManifest.json does not match the package contract" || return 1
	}
	pass "Cloudron manifest contract"
	jq --exit-status '.stable == true and (.versions | type == "object")' "${ROOT_DIR}/CloudronVersions.json" >/dev/null || {
		fail "CloudronVersions.json does not match the catalog contract" || return 1
	}
	assert_contains CHANGELOG '[0.1.3]' || return 1
	assert_contains PUBLISHING.md 'cloudron versions update --version=<VERSION> --state=published' || return 1
	jq -e '.versions["0.1.2"].publishState == "published"' "${ROOT_DIR}/CloudronVersions.json" >/dev/null || fail "Published catalog state contract failed" || return 1
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

	if git -C "$ROOT_DIR" ls-files -s | grep -Eq '^120000 '; then
		fail "Published source must not contain tracked symlinks" || return 1
	fi
	if git -C "$ROOT_DIR" grep -IEn '(/Users/[^/[:space:]]+/|/home/[^/[:space:]]+/)' -- . ':!test/package-test.sh'; then
		fail "Published source must not contain absolute user home-directory paths" || return 1
	fi
	pass "Public source path safety"

	assert_contains .agents/AGENTS.md 'wss://<app-host>' || return 1
	assert_contains .agents/AGENTS.md "public \`npub\` or hexadecimal public key" || return 1
	assert_contains .agents/AGENTS.md "transmit an \`nsec\` or any other private key" || return 1
	assert_contains .agents/AGENTS.md '/app/code/buzz-ctl set-owner <NPUB_OR_HEX_PUBKEY>' || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "tags:" || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "- 'v*'" || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "uses: marcusquinn/aidevops/.github/workflows/cloudron-package-release-reusable.yml@22a6b4b29087ce2fcf3857596a40ff7b2c436482" || return 1
	assert_contains .github/workflows/cloudron-package-release.yml "aidevops_ref: 22a6b4b29087ce2fcf3857596a40ff7b2c436482" || return 1
	pass "Managed release workflow and private-community onboarding"

	assert_contains Dockerfile "ghcr.io/block/buzz:sha-710ed9f@sha256:398f0497a88e3811339a23cf1081771dbd7a27a892ed12905c485d3c48a3bc19" || return 1
	assert_contains THIRD_PARTY_NOTICES.md "ghcr.io/block/buzz:sha-710ed9f@sha256:398f0497a88e3811339a23cf1081771dbd7a27a892ed12905c485d3c48a3bc19" || return 1
	assert_contains Dockerfile "minio/minio:RELEASE.2025-09-07T16-13-09Z@sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2" || return 1
	assert_contains Dockerfile "minio/mc:RELEASE.2025-08-13T08-35-41Z@sha256:eb4ea9884b77704230e2423e9004d2fa738dc272876b9cc41a297d29443b8780" || return 1
	assert_contains Dockerfile "cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c" || return 1
	if grep -Eq "^FROM[[:space:]]+[^[:space:]@]+(:latest)?([[:space:]]|$)" "${ROOT_DIR}/Dockerfile"; then
		fail "Every Docker stage must be tag-and-digest pinned" || return 1
	fi
	pass "Container provenance pins"

	for shell_script in start.sh run-minio.sh run-relay.sh buzz-ctl test/package-test.sh; do
		bash -n "${ROOT_DIR}/${shell_script}"
		shellcheck "${ROOT_DIR}/${shell_script}"
	done
	pass "Bash syntax and ShellCheck"

	assert_contains run-relay.sh "BUZZ_REQUIRE_AUTH_TOKEN=\"\$FEATURE_ENABLED\"" || return 1
	assert_contains run-relay.sh "BUZZ_REQUIRE_RELAY_MEMBERSHIP=\"\$FEATURE_ENABLED\"" || return 1
	assert_contains run-relay.sh "BUZZ_REQUIRE_MEDIA_GET_AUTH=\"\$FEATURE_ENABLED\"" || return 1
	assert_contains run-relay.sh "BUZZ_PUSH_GATEWAY_DELIVERY_URL=\"\"" || return 1
	assert_contains run-relay.sh "BUZZ_GIT_REPO_PATH=\"\${RUN_DIR}/git-repos\"" || return 1
	pass "Production security defaults"

	if grep -Eq "printf.*(PRIVATE_KEY|SECRET_KEY|PASSWORD)|echo.*(PRIVATE_KEY|SECRET_KEY|PASSWORD)" "${ROOT_DIR}/start.sh" "${ROOT_DIR}/run-minio.sh" "${ROOT_DIR}/run-relay.sh" "${ROOT_DIR}/buzz-ctl"; then
		fail "A runtime script may print secret material" || return 1
	fi
	pass "No obvious secret disclosure"
	return 0
}

main "$@"
