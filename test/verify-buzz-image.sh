#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

# Upstream main snapshot: no desktop release contains NIP-CL relay support yet.
# desktop-v0.5.28 (f87c1089...) predates d28f6b2f, so the pin is a main commit.
readonly BUZZ_NIP_CL_REVISION="d28f6b2f7095b50a2c987a42e9b4ca345f8e9dac"
readonly BUZZ_REVISION="2cd40badb85de059a6916206e133da7a0a88fb2e"
readonly BUZZ_IMAGE="ghcr.io/block/buzz:sha-2cd40ba"
readonly BUZZ_INDEX_DIGEST="sha256:1155b29cdcfdcb464ca42c73db7e4dbdc6680775d1c0d6aad26ab737a3fd0cfa"
readonly BUZZ_AMD64_DIGEST="sha256:6ff07e58c605ad5c77c5c4ae6ad4ed73bcb89d2734287254ab563ed03a138330"

github_api() {
	local endpoint="$1"
	# Reusable preflight runs without tokens. These are public upstream reads,
	# with the same pinned revision and ancestry validation on either path.
	if [[ -n "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]]; then
		gh api "repos/block/buzz/${endpoint}" || return 1
	else
		curl --fail --silent --show-error --retry 3 \
			--header 'Accept: application/vnd.github+json' \
			"https://api.github.com/repos/block/buzz/${endpoint}" || return 1
	fi
	return 0
}

main() {
	local image_metadata=""
	local ancestry_metadata=""

	for command_name in docker gh jq curl; do
		if ! command -v "$command_name" >/dev/null; then
			printf "Missing required command: %s\n" "$command_name" >&2
			return 1
		fi
	done

	image_metadata=$(docker buildx imagetools inspect "$BUZZ_IMAGE" --format '{{json .}}') || return 1
	jq --exit-status \
		--arg index_digest "$BUZZ_INDEX_DIGEST" \
		--arg amd64_digest "$BUZZ_AMD64_DIGEST" \
		--arg revision "$BUZZ_REVISION" \
		'.manifest.digest == $index_digest
		and any(.manifest.manifests[]; .digest == $amd64_digest and .platform.os == "linux" and .platform.architecture == "amd64")
		and .image["linux/amd64"].config.Labels["org.opencontainers.image.revision"] == $revision' \
		<<<"$image_metadata" >/dev/null || {
		printf "Buzz registry metadata does not match the pinned index, linux/amd64 image, and revision\n" >&2
		return 1
	}

	ancestry_metadata=$(github_api "compare/${BUZZ_NIP_CL_REVISION}...${BUZZ_REVISION}") || return 1
	jq --exit-status '(.status == "ahead" or .status == "identical") and .behind_by == 0' \
		<<<"$ancestry_metadata" >/dev/null || {
		printf "Buzz image revision does not contain NIP-CL relay commit %s\n" "$BUZZ_NIP_CL_REVISION" >&2
		return 1
	}

	printf "Verified index %s, linux/amd64 %s, image revision %s, contains NIP-CL commit %s\n" \
		"$BUZZ_INDEX_DIGEST" "$BUZZ_AMD64_DIGEST" "$BUZZ_REVISION" "$BUZZ_NIP_CL_REVISION"
	return 0
}

main "$@"
