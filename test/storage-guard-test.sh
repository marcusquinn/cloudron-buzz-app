#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn
#
# Runtime test of the storage startup guard (storage-setup.sh) and
# buzz-ctl storage-purge-legacy against the built image. Needs only Docker:
# PostgreSQL and Redis point at unreachable loopback ports because the guard
# decides before the relay connects to either.

set -euo pipefail

readonly IMAGE="${1:-cloudron-buzz-app:test}"
readonly PREFIX="buzz-guard-$$"
readonly RECORD=/app/data/config/storage-migration.json
readonly SCENARIOS="fresh metadata legacy failed malformed unknown migrated"
failures=0

pass() {
	local message="$1"
	printf "PASS: %s\n" "$message"
	return 0
}

fail() {
	local message="$1"
	printf "FAIL: %s\n" "$message" >&2
	failures=$((failures + 1))
	return 0
}

check() {
	local message="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		pass "$message"
	else
		fail "$message"
	fi
	return 0
}

cleanup() {
	local scenario=""
	for scenario in $SCENARIOS; do
		docker rm -f "${PREFIX}-${scenario}" >/dev/null 2>&1 || true
		docker volume rm -f "${PREFIX}-${scenario}" >/dev/null 2>&1 || true
	done
	return 0
}

in_app() {
	local scenario="$1"
	shift
	docker exec "${PREFIX}-${scenario}" "$@"
	return $?
}

# Seeds /app/data before first start. Legacy objects are plain files: the
# guard treats any file outside .minio.sys as unmigrated user data.
seed() {
	local scenario="$1"
	local script="$2"
	docker volume create "${PREFIX}-${scenario}" >/dev/null || return 1
	docker run --rm --platform linux/amd64 --entrypoint /bin/bash \
		-v "${PREFIX}-${scenario}:/app/data" "$IMAGE" -c "set -e; mkdir -p /app/data/config; ${script}; chown -R cloudron:cloudron /app/data" || return 1
	return 0
}

start_app() {
	local scenario="$1"
	docker run --detach --name "${PREFIX}-${scenario}" --platform linux/amd64 --read-only \
		--tmpfs /run:exec --tmpfs /tmp -v "${PREFIX}-${scenario}:/app/data" \
		-e CLOUDRON_APP_DOMAIN=buzz.example.test \
		-e CLOUDRON_APP_ORIGIN=https://buzz.example.test \
		-e CLOUDRON_POSTGRESQL_URL=postgres://buzz:unused@127.0.0.1:1/buzz \
		-e CLOUDRON_REDIS_URL=redis://127.0.0.1:1 \
		"$IMAGE" >/dev/null || return 1
	return 0
}

program_status() {
	local scenario="$1"
	local program="$2"
	in_app "$scenario" /usr/bin/supervisorctl -c /app/code/supervisord.conf status "$program" 2>/dev/null || true
	return 0
}

# Storage setup has finished once supervisor reports it EXITED or FATAL.
wait_setup() {
	local scenario="$1"
	local attempt=0
	local status=""
	for ((attempt = 0; attempt < 180; attempt++)); do
		status=$(program_status "$scenario" storage-setup)
		if [[ "$status" == *EXITED* || "$status" == *FATAL* ]]; then
			return 0
		fi
		sleep 1
	done
	printf "storage-setup did not finish in %s\n" "$scenario" >&2
	docker logs "${PREFIX}-${scenario}" 2>&1 | tail -30 >&2
	return 1
}

logs_contain() {
	local scenario="$1"
	local text="$2"
	local output=""
	# Capture first: grep -q closing the pipe early would fail under pipefail.
	output=$(docker logs "${PREFIX}-${scenario}" 2>&1) || return 1
	[[ "$output" == *"$text"* ]]
	return $?
}

not_started() {
	local scenario="$1"
	local program="$2"
	[[ "$(program_status "$scenario" "$program")" == *"Not started"* ]]
	return $?
}

record_state_is() {
	local scenario="$1"
	local expected="$2"
	[[ "$(in_app "$scenario" jq -r '.state' "$RECORD")" == "$expected" ]]
	return $?
}

proceeded() {
	local scenario="$1"
	in_app "$scenario" test -f /run/buzz/storage.json || return 1
	[[ "$(program_status "$scenario" rustfs)" == *RUNNING* ]]
	return $?
}

assert_refused() {
	local scenario="$1"
	local reason="$2"
	check "${scenario}: logs refusal reason" logs_contain "$scenario" "$reason"
	check "${scenario}: logs recovery steps" logs_contain "$scenario" "ERROR: Recovery: restore the backup taken before this update"
	check "${scenario}: RustFS not started" not_started "$scenario" rustfs
	check "${scenario}: relay not started" not_started "$scenario" buzz-relay
	check "${scenario}: active storage not published" bash -c "! docker exec '${PREFIX}-${scenario}' test -e /run/buzz/storage.json"
	return 0
}

purge() {
	local scenario="$1"
	shift
	in_app "$scenario" /app/code/buzz-ctl storage-purge-legacy "$@"
	return $?
}

purge_fails() {
	local scenario="$1"
	shift
	if purge "$scenario" "$@"; then
		return 1
	fi
	return 0
}

legacy_keys() {
	local scenario="$1"
	in_app "$scenario" find /app/data/config -maxdepth 1 -name 'minio-*-key' | wc -l | tr -d ' '
	return 0
}

check_purge() {
	local scenario=migrated
	check "purge: refused for non-root" bash -c "! docker exec --user cloudron '${PREFIX}-${scenario}' /app/code/buzz-ctl storage-purge-legacy --confirm"
	check "purge: preview exits non-zero" purge_fails "$scenario"
	check "purge: preview keeps legacy data" in_app "$scenario" test -f /app/data/minio/buzz-data/media/proof.txt
	check "purge: --confirm succeeds" purge "$scenario" --confirm
	check "purge: legacy directory removed" bash -c "! docker exec '${PREFIX}-${scenario}' test -e /app/data/minio"
	check "purge: legacy credentials removed" test "$(legacy_keys "$scenario")" = 0
	check "purge: RustFS credentials kept" in_app "$scenario" test -s /app/data/config/rustfs-secret-key
	check "purge: repeat is idempotent" purge "$scenario" --confirm
	in_app "$scenario" sh -c 'umask 077; printf x >/app/data/config/minio-access-key; printf y >/app/data/config/minio-secret-key'
	check "purge: leftover credentials preview exits non-zero" purge_fails "$scenario"
	check "purge: leftover credentials kept by preview" test "$(legacy_keys "$scenario")" = 2
	check "purge: leftover credentials removed by --confirm" purge "$scenario" --confirm
	check "purge: no legacy credentials remain" test "$(legacy_keys "$scenario")" = 0
	check "purge: refused without a storage record" purge_fails legacy --confirm
	check "purge: refused for failed record" purge_fails failed --confirm
	check "purge: failed install keeps legacy data" in_app failed test -f /app/data/minio/buzz-data/media/proof.txt
	return 0
}

# Prints a seed command writing a 0.1.26-style storage record with STATE.
write_record() {
	local state="$1"
	printf "printf '%s' '{\"state\":\"%s\",\"active\":\"rustfs\",\"source_count\":1,\"destination_count\":1,\"timestamp\":\"2026-11-01T00:00:00Z\",\"package_version\":\"0.1.26\"}' >%s" '%s' "$state" "$RECORD"
	return 0
}

main() {
	local scenario=""
	local legacy_object="mkdir -p /app/data/minio/buzz-data/media; printf proof >/app/data/minio/buzz-data/media/proof.txt"

	docker image inspect "$IMAGE" >/dev/null
	trap cleanup EXIT
	seed fresh "true"
	seed metadata "mkdir -p /app/data/minio/.minio.sys; printf '{}' >/app/data/minio/.minio.sys/format.json"
	seed legacy "$legacy_object"
	seed failed "${legacy_object}; $(write_record failed)"
	seed malformed "${legacy_object}; printf '{not json' >${RECORD}"
	seed unknown "${legacy_object}; $(write_record pending)"
	seed migrated "${legacy_object}; printf x >/app/data/config/minio-access-key; printf y >/app/data/config/minio-secret-key; $(write_record migrated)"

	for scenario in $SCENARIOS; do
		start_app "$scenario"
	done
	for scenario in $SCENARIOS; do
		wait_setup "$scenario"
	done

	check "fresh: storage setup proceeds" proceeded fresh
	check "fresh: records not-needed" record_state_is fresh not-needed
	check "fresh: creates no legacy directory" bash -c "! docker exec '${PREFIX}-fresh' test -e /app/data/minio"
	check "metadata-only legacy directory: proceeds" proceeded metadata
	check "metadata-only legacy directory: records not-needed" record_state_is metadata not-needed

	assert_refused legacy "were never migrated to RustFS (storage state: none)"
	check "legacy: writes no storage record" bash -c "! docker exec '${PREFIX}-legacy' test -e '${RECORD}'"
	check "legacy: keeps legacy data" in_app legacy test -f /app/data/minio/buzz-data/media/proof.txt
	assert_refused failed "were never migrated to RustFS (storage state: failed)"
	check "failed: record unchanged" record_state_is failed failed
	assert_refused malformed "is unreadable or has an unknown state"
	assert_refused unknown "is unreadable or has an unknown state"

	check "migrated: storage setup proceeds" proceeded migrated
	check "migrated: record unchanged" record_state_is migrated migrated
	check "migrated: startup keeps legacy data" in_app migrated test -f /app/data/minio/buzz-data/media/proof.txt
	check_purge

	if ((failures > 0)); then
		printf "Storage guard test: %s check(s) failed\n" "$failures" >&2
		return 1
	fi
	printf "PASS: storage guard and legacy purge runtime contract\n"
	return 0
}

main "$@"
