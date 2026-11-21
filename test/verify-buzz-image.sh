#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

# Buzz 1.x desktop releases come from block/buzz-app; the relay still comes
# from block/buzz main images. Each app release pins the block/buzz revision it
# was built against (src-tauri/Cargo.toml, buzz-audio-client), so the packaged
# relay must contain that revision. The NIP-CL relay commit remains a floor.
readonly BUZZ_APP_RELEASE="v1.0.6"
readonly BUZZ_APP_RELAY_REVISION="630922a9e1f891380a61f5b7d726d05ca948cc64"
readonly BUZZ_NIP_CL_REVISION="d28f6b2f7095b50a2c987a42e9b4ca345f8e9dac"
readonly BUZZ_REVISION="c0ce4982fcbbc379255fde6762487d5808d8d2b4"
readonly BUZZ_IMAGE="ghcr.io/block/buzz:sha-c0ce498"
readonly BUZZ_INDEX_DIGEST="sha256:581f5067e78ffeaf1b6c4077cb5d31a6923ff89755c0faa295f5b9f9ec1ae31a"
readonly BUZZ_AMD64_DIGEST="sha256:d46200c80b010fb555811683df5d101592d9495cb0cfdfc3e330fffd72a6ab4e"

github_api() {
	local repository="$1"
	local endpoint="$2"
	# Reusable preflight runs without tokens. These are public upstream reads,
	# with the same pinned revision and ancestry validation on either path.
	if [[ -n "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]]; then
		gh api "repos/${repository}/${endpoint}" || return 1
	else
		curl --fail --silent --show-error --retry 3 \
			--header 'Accept: application/vnd.github+json' \
			"https://api.github.com/repos/${repository}/${endpoint}" || return 1
	fi
	return 0
}

assert_contains_revision() {
	local revision="$1"
	local description="$2"
	local ancestry_metadata=""

	ancestry_metadata=$(github_api block/buzz "compare/${revision}...${BUZZ_REVISION}") || return 1
	jq --exit-status '(.status == "ahead" or .status == "identical") and .behind_by == 0' \
		<<<"$ancestry_metadata" >/dev/null || {
		printf "Buzz image revision does not contain %s %s\n" "$description" "$revision" >&2
		return 1
	}
	return 0
}

main() {
	local image_metadata=""
	local app_cargo=""
	local app_pin=""

	for command_name in docker gh jq curl base64; do
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

	app_cargo=$(github_api block/buzz-app "contents/src-tauri/Cargo.toml?ref=${BUZZ_APP_RELEASE}" | jq -r '.content' | base64 --decode) || return 1
	app_pin=$(sed -nE 's/^buzz-audio-client = .*rev = "([0-9a-f]{40})".*/\1/p' <<<"$app_cargo")
	[[ "$app_pin" == "$BUZZ_APP_RELAY_REVISION" ]] || {
		printf "Buzz app %s pins relay revision %s, expected %s\n" "$BUZZ_APP_RELEASE" "${app_pin:-none}" "$BUZZ_APP_RELAY_REVISION" >&2
		return 1
	}

	assert_contains_revision "$BUZZ_NIP_CL_REVISION" "NIP-CL relay commit" || return 1
	assert_contains_revision "$BUZZ_APP_RELAY_REVISION" "Buzz app ${BUZZ_APP_RELEASE} relay revision" || return 1

	printf "Verified index %s, linux/amd64 %s, image revision %s, contains NIP-CL commit %s and Buzz app %s relay revision %s\n" \
		"$BUZZ_INDEX_DIGEST" "$BUZZ_AMD64_DIGEST" "$BUZZ_REVISION" "$BUZZ_NIP_CL_REVISION" "$BUZZ_APP_RELEASE" "$BUZZ_APP_RELAY_REVISION"
	return 0
}

main "$@"
