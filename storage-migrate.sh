#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn
set -euo pipefail
umask 077

readonly RECORD=/app/data/config/storage-migration.json
readonly ACTIVE=/run/buzz/storage.json
readonly WORK=/run/buzz/migration

ctl() {
	local action="$1"
	local program="$2"
	local status=""
	local attempt=0
	# The setup child may run before supervisor opens its RPC socket.
	for ((attempt = 0; attempt < 30; attempt++)); do
		[[ -S /run/supervisor/supervisor.sock ]] && break
		sleep 1
	done
	status=$(/usr/bin/supervisorctl -c /app/code/supervisord.conf status "$program" 2>/dev/null) || true
	if [[ "$action" == start && "$status" == *RUNNING* ]]; then
		return 0
	fi
	if [[ "$action" == stop && ( "$status" == *STOPPED* || "$status" == *EXITED* || "$status" == *FATAL* ) ]]; then
		return 0
	fi
	/usr/bin/supervisorctl -c /app/code/supervisord.conf "$action" "$program" || return 1
	return 0
}

mc() {
	MC_CONFIG_DIR="$WORK/mc" /app/code/bin/mcli "$@" || return 1
	return 0
}

ready() {
	local endpoint="$1"
	local attempt=0
	for ((attempt = 0; attempt < 90; attempt++)); do
		if curl --fail --silent --max-time 2 "$endpoint" >/dev/null; then
			return 0
		fi
		sleep 1
	done
	return 1
}

alias_store() {
	local name="$1"
	local endpoint="$2"
	local prefix="$3"
	[[ ! -L "/app/data/config/${prefix}-access-key" && ! -L "/app/data/config/${prefix}-secret-key" ]] || return 1
	# mcli config version 10; keep credentials out of process arguments.
	[[ -f "$WORK/mc/config.json" ]] || printf '{"version":"10","aliases":{}}\n' >"$WORK/mc/config.json"
	jq --arg name "$name" --arg endpoint "$endpoint" \
		--rawfile access "/app/data/config/${prefix}-access-key" \
		--rawfile secret "/app/data/config/${prefix}-secret-key" \
		'.aliases[$name] = {url:$endpoint,accessKey:($access|rtrimstr("\n")),secretKey:($secret|rtrimstr("\n")),api:"S3v4",path:"auto"}' \
		"$WORK/mc/config.json" >"$WORK/mc/config.next" || return 1
	mv -f "$WORK/mc/config.next" "$WORK/mc/config.json" || return 1
	return 0
}

publish_active() {
	local temporary=""
	[[ ! -L "$ACTIVE" ]] || return 1
	temporary=$(mktemp /run/buzz/storage.XXXXXX) || return 1
	cp "$RECORD" "$temporary" || return 1
	chown cloudron:cloudron "$temporary" || return 1
	mv -f "$temporary" "$ACTIVE" || return 1
	return 0
}

record() {
	local state="$1"
	local store="$2"
	local source_count="$3"
	local destination_count="$4"
	local temporary=""
	local version=""
	[[ ! -L "$RECORD" && ! -L "$ACTIVE" ]] || return 1
	version=$(jq -er '.version' /app/code/CloudronManifest.json) || return 1
	temporary=$(mktemp /app/data/config/storage-migration.XXXXXX) || return 1
	jq -n --arg state "$state" --arg active "$store" --arg version "$version" \
		--arg timestamp "$(date -u +%FT%TZ)" --argjson source "$source_count" --argjson destination "$destination_count" \
		'{state:$state,active:$active,source_count:$source,destination_count:$destination,timestamp:$timestamp,package_version:$version}' >"$temporary" || return 1
	chown cloudron:cloudron "$temporary" || return 1
	mv -f "$temporary" "$RECORD" || return 1
	publish_active || return 1
	return 0
}

inventory() {
	local bucket="$1"
	local output="$2"
	# Pipeline errors propagate: a failed or truncated listing cannot verify a copy.
	mc ls --recursive --json "$bucket" | jq -s -e '
		if any(.[]; .status != "success") then error("listing failed")
		else [.[] | select(.type == "file") | {key:.key,size:.size}] | sort_by(.key) end' >"$output" || return 1
	return 0
}

migrate() {
	local source_count=0
	local destination_count=0
	ctl start rustfs >/dev/null || return 1
	ready http://127.0.0.1:9100/health/ready || return 1
	alias_store rustfs http://127.0.0.1:9100 rustfs || return 1
	mc mb --ignore-existing rustfs/buzz-data >/dev/null 2>&1 || return 1
	mc anonymous set none rustfs/buzz-data >/dev/null 2>&1 || return 1
	# No in-place format conversion and no writes/deletes to legacy/buzz-data.
	# Only the not-yet-authoritative destination is reconciled on retry.
	mc mirror --overwrite --remove legacy/buzz-data rustfs/buzz-data >"$WORK/mirror.log" 2>&1 || return 1
	inventory legacy/buzz-data "$WORK/source.json" || return 1
	inventory rustfs/buzz-data "$WORK/destination.json" || return 1
	cmp -s "$WORK/source.json" "$WORK/destination.json" || return 1
	source_count=$(jq length "$WORK/source.json") || return 1
	destination_count=$(jq length "$WORK/destination.json") || return 1
	record migrated rustfs "$source_count" "$destination_count" || return 1
	return 0
}

main() {
	local state=""
	local legacy_file=""
	[[ "$EUID" == 0 ]] || { printf 'ERROR: storage migration requires root\n' >&2; return 1; }
	# Serialize startup and manual retry; never recopy while the relay writes.
	exec 9>/run/buzz/storage-migration.lock
	flock -n 9 || return 1
	[[ ! -L "$WORK" && ! -L "$RECORD" && ! -L "$ACTIVE" ]] || return 1
	mkdir -p "$WORK/mc"
	ctl stop buzz-relay >/dev/null || return 1
	if [[ -f "$RECORD" ]]; then
		state=$(jq -er '.state | select(. == "migrated" or . == "not-needed" or . == "failed")' "$RECORD") || return 1
	fi
	if [[ "$state" == migrated || "$state" == not-needed ]]; then
		ctl start rustfs >/dev/null || return 1
		ready http://127.0.0.1:9100/health/ready || return 1
		publish_active || return 1
	else
		# System metadata alone is not legacy user data.
		legacy_file=$(find /app/data/minio -path /app/data/minio/.minio.sys -prune -o -type f -print -quit) || return 1
		if [[ -z "$legacy_file" ]]; then
			ctl start rustfs >/dev/null || return 1
			ready http://127.0.0.1:9100/health/ready || return 1
			record not-needed rustfs 0 0 || return 1
		else
			ctl start minio >/dev/null || return 1
			ready http://127.0.0.1:9000/minio/health/ready || return 1
			alias_store legacy http://127.0.0.1:9000 minio || return 1
			if ! migrate; then
				# A durable commit must never be downgraded to Silo if runtime
				# publication failed. Leave the relay stopped; restart recovers.
				if [[ -f "$RECORD" ]] && jq -e '.state == "migrated"' "$RECORD" >/dev/null; then
					printf 'ERROR: Migration committed but activation failed; relay remains stopped. Restart to recover.\n' >&2
					return 1
				fi
				printf 'ERROR: RustFS migration failed; retaining Silo. Restart or storage-migrate retries.\n' >&2
				record failed silo null null || return 1
				ctl stop rustfs >/dev/null || printf 'WARNING: RustFS shutdown failed; relay still uses Silo\n' >&2
			fi
		fi
	fi
	if jq -e '.active == "rustfs"' "$ACTIVE" >/dev/null; then
		ctl stop minio >/dev/null || return 1
	fi
	ctl start buzz-relay >/dev/null || return 1
	printf '==> Storage selection completed\n'
	return 0
}

main "$@"
