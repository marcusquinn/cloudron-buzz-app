#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

readonly BUZZ_RELEASE="desktop-v0.5.17"
readonly BUZZ_RELEASE_REVISION="c3bfd66947978fae93f4cfb46bea98ba20e32ccf"
readonly BUZZ_REVISION="3fdf289b78c40f80abce86575c25b5ed6361d82c"
readonly BUZZ_IMAGE="ghcr.io/block/buzz:sha-3fdf289"
readonly BUZZ_INDEX_DIGEST="sha256:63893f41316fb8cfb08296fd6a5236460454262965cc7c44de66ac147dd12ff8"
readonly BUZZ_AMD64_DIGEST="sha256:c7dde8e96c96f818a49f2d188ff9225b3c05be29e4d051f1333926d7f49fff84"

main() {
	local image_metadata=""
	local release_object=""
	local release_object_sha=""
	local release_object_type=""
	local release_revision=""
	local release_tag_depth=0
	local ancestry_metadata=""

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

	release_object=$(gh api "repos/block/buzz/git/ref/tags/${BUZZ_RELEASE}") || return 1
	release_object_sha=$(jq --raw-output '.object.sha' <<<"$release_object") || return 1
	release_object_type=$(jq --raw-output '.object.type' <<<"$release_object") || return 1
	while [[ "$release_object_type" == "tag" ]]; do
		release_tag_depth=$((release_tag_depth + 1))
		if ((release_tag_depth > 10)); then
			printf "Buzz release %s exceeds the annotated-tag resolution limit\n" "$BUZZ_RELEASE" >&2
			return 1
		fi
		release_object=$(gh api "repos/block/buzz/git/tags/${release_object_sha}") || return 1
		release_object_sha=$(jq --raw-output '.object.sha' <<<"$release_object") || return 1
		release_object_type=$(jq --raw-output '.object.type' <<<"$release_object") || return 1
	done
	if [[ "$release_object_type" != "commit" ]]; then
		printf "Buzz release %s resolves to unexpected object type %s\n" "$BUZZ_RELEASE" "$release_object_type" >&2
		return 1
	fi
	release_revision="$release_object_sha"
	if [[ "$release_revision" != "$BUZZ_RELEASE_REVISION" ]]; then
		printf "Buzz release %s resolves to unexpected revision %s\n" "$BUZZ_RELEASE" "$release_revision" >&2
		return 1
	fi
	ancestry_metadata=$(gh api "repos/block/buzz/compare/${BUZZ_REVISION}...${BUZZ_RELEASE_REVISION}") || return 1
	jq --exit-status '.status == "ahead" and .ahead_by == 1 and .behind_by == 0' \
		<<<"$ancestry_metadata" >/dev/null || {
		printf "Buzz image revision is not the immediate ancestor of release %s\n" "$BUZZ_RELEASE" >&2
		return 1
	}

	printf "Verified %s: index %s, linux/amd64 %s, image revision %s, release revision %s\n" \
		"$BUZZ_RELEASE" "$BUZZ_INDEX_DIGEST" "$BUZZ_AMD64_DIGEST" "$BUZZ_REVISION" "$BUZZ_RELEASE_REVISION"
	return 0
}

main "$@"
