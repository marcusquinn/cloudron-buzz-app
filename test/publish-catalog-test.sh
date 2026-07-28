#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

TEST_DIR=""
TEST_DIR=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
readonly TEST_DIR
readonly PUBLISHER="${TEST_DIR%/*}/scripts/publish-cloudron-catalog.sh"
TEST_ROOT=""
PASSED=0
FAILED=0

cleanup() {
	if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
		rm -rf "$TEST_ROOT"
	fi
	return 0
}

pass() {
	local description="$1"
	printf "PASS: %s\n" "$description"
	PASSED=$((PASSED + 1))
	return 0
}

fail() {
	local description="$1"
	printf "FAIL: %s\n" "$description" >&2
	FAILED=$((FAILED + 1))
	return 0
}

write_fake_cloudron() {
	local bin_dir="$1"
	mkdir -p "$bin_dir"
	cat >"${bin_dir}/cloudron" <<'FAKE'
#!/bin/bash
set -euo pipefail
command_name="${1:-}"
subcommand="${2:-}"
shift 2
[[ "$command_name" == "versions" ]] || exit 1
case "$subcommand" in
	add)
		image=""
		state=""
		while [[ $# -gt 0 ]]; do
			case "$1" in
				--image) image="${2:-}"; shift 2 ;;
				--state) state="${2:-}"; shift 2 ;;
				*) shift ;;
			esac
		done
		version=$(jq -r '.version' CloudronManifest.json)
		manifest=$(jq -c --arg image "$image" '. + {dockerImage: $image}' CloudronManifest.json)
		[[ "${FAKE_CLOUDRON_CORRUPT:-false}" != true ]] || manifest=$(jq -c '.dockerImage = "mutable:tag"' <<<"$manifest")
		tmp=$(mktemp)
		jq --arg version "$version" --arg state "$state" --argjson manifest "$manifest" \
			'.versions[$version] = {manifest: $manifest, creationDate: "test", ts: "test", publishState: $state}' \
			CloudronVersions.json >"$tmp"
		mv "$tmp" CloudronVersions.json
		;;
	update)
		image=""
		version=""
		state=""
		while [[ $# -gt 0 ]]; do
			case "$1" in
				--image) image="${2:-}"; shift 2 ;;
				--version) version="${2:-}"; shift 2 ;;
				--state) state="${2:-}"; shift 2 ;;
				*) shift ;;
			esac
		done
		tmp=$(mktemp)
		jq --arg image "$image" --arg version "$version" --arg state "$state" \
			'.versions[$version].manifest.dockerImage = $image | .versions[$version].publishState = $state' \
			CloudronVersions.json >"$tmp"
		mv "$tmp" CloudronVersions.json
		;;
	*) exit 1 ;;
esac
FAKE
	chmod 0755 "${bin_dir}/cloudron"
	return 0
}

write_fixture() {
	local fixture_dir="$1"
	mkdir -p "$fixture_dir"
	cat >"${fixture_dir}/CloudronManifest.json" <<'JSON'
{
  "id": "example.test",
  "title": "Example",
  "version": "1.2.3",
  "upstreamVersion": "4.5.6",
  "manifestVersion": 2
}
JSON
	cat >"${fixture_dir}/CloudronVersions.json" <<'JSON'
{
  "stable": true,
  "versions": {}
}
JSON
	return 0
}

test_valid_publication() {
	local fixture_dir="${TEST_ROOT}/valid"
	local bin_dir="${TEST_ROOT}/bin"
	local image_ref="ghcr.io/example/package@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	write_fixture "$fixture_dir"
	write_fake_cloudron "$bin_dir"
	if CLOUDRON_PACKAGE_ROOT="$fixture_dir" PATH="${bin_dir}:$PATH" "$PUBLISHER" "$image_ref" >/dev/null; then
		pass "immutable image is published"
	else
		fail "immutable image is published"
		return 0
	fi
	if jq --exit-status --arg image "$image_ref" '.versions["1.2.3"].publishState == "published" and .versions["1.2.3"].manifest.dockerImage == $image' "${fixture_dir}/CloudronVersions.json" >/dev/null; then
		pass "published entry preserves the exact digest reference"
	else
		fail "published entry preserves the exact digest reference"
	fi
	return 0
}

test_mutable_reference_rejected() {
	local fixture_dir="${TEST_ROOT}/mutable"
	local bin_dir="${TEST_ROOT}/bin"
	write_fixture "$fixture_dir"
	write_fake_cloudron "$bin_dir"
	if CLOUDRON_PACKAGE_ROOT="$fixture_dir" PATH="${bin_dir}:$PATH" "$PUBLISHER" "ghcr.io/example/package:1.2.3" >/dev/null 2>&1; then
		fail "mutable image reference is rejected"
	else
		pass "mutable image reference is rejected"
	fi
	return 0
}

test_existing_version_rejected() {
	local fixture_dir="${TEST_ROOT}/existing"
	local bin_dir="${TEST_ROOT}/bin"
	local before=""
	write_fixture "$fixture_dir"
	write_fake_cloudron "$bin_dir"
	jq '.versions["1.2.3"] = {publishState: "published"}' "${fixture_dir}/CloudronVersions.json" >"${fixture_dir}/existing.json"
	mv "${fixture_dir}/existing.json" "${fixture_dir}/CloudronVersions.json"
	before=$(cksum "${fixture_dir}/CloudronVersions.json")
	if CLOUDRON_PACKAGE_ROOT="$fixture_dir" PATH="${bin_dir}:$PATH" "$PUBLISHER" "ghcr.io/example/package@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" >/dev/null 2>&1; then
		fail "existing package version is rejected"
	else
		pass "existing package version is rejected"
	fi
	if [[ "$before" == "$(cksum "${fixture_dir}/CloudronVersions.json")" ]]; then
		pass "existing catalog remains unchanged"
	else
		fail "existing catalog remains unchanged"
	fi
	return 0
}

test_invalid_cli_output_rolls_back() {
	local fixture_dir="${TEST_ROOT}/rollback"
	local bin_dir="${TEST_ROOT}/bin"
	local before=""
	write_fixture "$fixture_dir"
	write_fake_cloudron "$bin_dir"
	before=$(cksum "${fixture_dir}/CloudronVersions.json")
	if CLOUDRON_PACKAGE_ROOT="$fixture_dir" FAKE_CLOUDRON_CORRUPT=true PATH="${bin_dir}:$PATH" "$PUBLISHER" "ghcr.io/example/package@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc" >/dev/null 2>&1; then
		fail "invalid Cloudron CLI output is rejected"
	else
		pass "invalid Cloudron CLI output is rejected"
	fi
	if [[ "$before" == "$(cksum "${fixture_dir}/CloudronVersions.json")" ]]; then
		pass "failed publication restores the catalog"
	else
		fail "failed publication restores the catalog"
	fi
	return 0
}

main() {
	TEST_ROOT=$(mktemp -d)
	trap cleanup EXIT
	test_valid_publication
	test_mutable_reference_rejected
	test_existing_version_rejected
	test_invalid_cli_output_rolls_back
	printf "Ran %d catalog publication tests; %d failed.\n" "$((PASSED + FAILED))" "$FAILED"
	[[ "$FAILED" -eq 0 ]] || return 1
	return 0
}

main "$@"
