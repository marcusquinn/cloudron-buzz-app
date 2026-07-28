#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

SCRIPT_DIR=""
SCRIPT_DIR=$(cd "${BASH_SOURCE[0]%/*}" && pwd)
readonly SCRIPT_DIR
ROOT_DIR="${CLOUDRON_PACKAGE_ROOT:-${SCRIPT_DIR%/*}}"
readonly ROOT_DIR
readonly CATALOG_PATH="${ROOT_DIR}/CloudronVersions.json"
readonly MANIFEST_PATH="${ROOT_DIR}/CloudronManifest.json"
CATALOG_BACKUP=""
CATALOG_COMMITTED=false

fail() {
	local message="$1"
	printf "ERROR: %s\n" "$message" >&2
	return 1
}

require_command() {
	local command_name="$1"
	if ! command -v "$command_name" >/dev/null 2>&1; then
		fail "Missing required command: ${command_name}" || return 1
	fi
	return 0
}

cleanup() {
	local status="$1"
	trap - EXIT
	if [[ "$CATALOG_COMMITTED" != true && -n "$CATALOG_BACKUP" && -f "$CATALOG_BACKUP" ]]; then
		cp "$CATALOG_BACKUP" "$CATALOG_PATH"
	fi
	if [[ -n "$CATALOG_BACKUP" ]]; then
		rm -f "$CATALOG_BACKUP"
	fi
	return "$status"
}

main() {
	local command_name=""
	local image_ref="${1:-}"
	local package_version=""

	for command_name in cloudron jq; do
		require_command "$command_name" || return 1
	done
	[[ -f "$MANIFEST_PATH" ]] || fail "CloudronManifest.json is missing" || return 1
	[[ -f "$CATALOG_PATH" ]] || fail "CloudronVersions.json is missing" || return 1
	if [[ ! "$image_ref" =~ ^[a-zA-Z0-9._/:@-]+@sha256:[0-9a-f]{64}$ ]]; then
		fail "Image must be an immutable registry reference ending in @sha256:<64 lowercase hex characters>" || return 1
	fi
	package_version=$(jq -er '.version | select(test("^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"))' "$MANIFEST_PATH") || {
		fail "Manifest version is missing or invalid" || return 1
	}
	if jq --exit-status --arg version "$package_version" '.versions | has($version)' "$CATALOG_PATH" >/dev/null; then
		fail "Catalog already contains package version ${package_version}" || return 1
	fi

	CATALOG_BACKUP=$(mktemp)
	cp "$CATALOG_PATH" "$CATALOG_BACKUP"
	trap 'cleanup "$?"' EXIT

	cd "$ROOT_DIR"
	cloudron versions add --image "$image_ref" --state testing || return 1
	jq --exit-status --arg version "$package_version" --arg image "$image_ref" '
		.versions[$version].manifest.version == $version and
		.versions[$version].manifest.dockerImage == $image and
		.versions[$version].publishState == "testing"
	' "$CATALOG_PATH" >/dev/null || {
		fail "Cloudron CLI did not generate the expected testing entry" || return 1
	}

	cloudron versions update --image "$image_ref" --version "$package_version" --state published || return 1
	jq --exit-status --arg version "$package_version" --arg image "$image_ref" '
		.versions[$version].manifest.version == $version and
		.versions[$version].manifest.dockerImage == $image and
		.versions[$version].publishState == "published"
	' "$CATALOG_PATH" >/dev/null || {
		fail "Cloudron CLI did not promote the expected immutable entry" || return 1
	}

	CATALOG_COMMITTED=true
	printf "Prepared published Cloudron catalog entry %s with %s\n" "$package_version" "$image_ref"
	return 0
}

main "$@"
