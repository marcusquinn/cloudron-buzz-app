#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

readonly BUZZ_RELEASE="v0.4.26"
readonly BUZZ_REVISION="0096d710ed2e6abab19aaf7cdc14e3ee603d7ec8"
readonly BUZZ_IMAGE="ghcr.io/block/buzz:sha-0096d71"
readonly BUZZ_INDEX_DIGEST="sha256:32a8c6aa8ca3617d767eb5743891f45d956c9cdbe161d244c8702a7645b64a78"
readonly BUZZ_AMD64_DIGEST="sha256:fffed2f1a5a7f14cd44d085dc323e78c26586de0b4832ff78dc518b3eabc7224"

main() {
	local image_metadata=""
	local release_revision=""

	for command_name in docker gh jq; do
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

	release_revision=$(gh api "repos/block/buzz/git/ref/tags/${BUZZ_RELEASE}" --jq '.object.sha') || return 1
	if [[ "$release_revision" != "$BUZZ_REVISION" ]]; then
		printf "Buzz release %s resolves to unexpected revision %s\n" "$BUZZ_RELEASE" "$release_revision" >&2
		return 1
	fi

	printf "Verified %s: index %s, linux/amd64 %s, revision %s\n" \
		"$BUZZ_RELEASE" "$BUZZ_INDEX_DIGEST" "$BUZZ_AMD64_DIGEST" "$BUZZ_REVISION"
	return 0
}

main "$@"
