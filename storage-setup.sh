#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn
set -euo pipefail
umask 077

readonly RECORD=/app/data/config/storage-migration.json
readonly ACTIVE=/run/buzz/storage.json
readonly LEGACY_DIR=/app/data/minio
readonly LAST_DUAL_STORE_RELEASE=0.1.26

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

publish_active() {
	local temporary=""
	[[ ! -L "$ACTIVE" ]] || return 1
	temporary=$(mktemp /run/buzz/storage.XXXXXX) || return 1
	cp "$RECORD" "$temporary" || return 1
	chown cloudron:cloudron "$temporary" || return 1
	mv -f "$temporary" "$ACTIVE" || return 1
	return 0
}

record_not_needed() {
	local temporary=""
	local version=""
	[[ ! -L "$RECORD" ]] || return 1
	version=$(jq -er '.version' /app/code/CloudronManifest.json) || return 1
	temporary=$(mktemp /app/data/config/storage-migration.XXXXXX) || return 1
	jq -n --arg version "$version" --arg timestamp "$(date -u +%FT%TZ)" \
		'{state:"not-needed",active:"rustfs",source_count:0,destination_count:0,timestamp:$timestamp,package_version:$version}' >"$temporary" || return 1
	chown cloudron:cloudron "$temporary" || return 1
	mv -f "$temporary" "$RECORD" || return 1
	return 0
}

# System metadata alone is not legacy user data.
has_legacy_objects() {
	local legacy_file=""
	[[ -d "$LEGACY_DIR" ]] || return 1
	[[ ! -L "$LEGACY_DIR" ]] || return 0
	legacy_file=$(find "$LEGACY_DIR" -path "${LEGACY_DIR}/.minio.sys" -prune -o -type f -print -quit) || return 0
	[[ -n "$legacy_file" ]]
	return $?
}

print_recovery() {
	printf 'ERROR: Recovery: restore the backup taken before this update, update to package %s (the last release with Silo),\n' "$LAST_DUAL_STORE_RELEASE" >&2
	printf 'ERROR: confirm that "buzz-ctl storage-status" reports state "migrated", then update to this release again.\n' >&2
	return 0
}

refuse_unmigrated() {
	local state="$1"
	printf 'ERROR: Legacy Silo/MinIO objects in %s were never migrated to RustFS (storage state: %s).\n' "$LEGACY_DIR" "$state" >&2
	printf 'ERROR: This release no longer includes Silo, so the relay will not start with incomplete media and Git data.\n' >&2
	print_recovery
	return 1
}

refuse_unreadable_record() {
	printf 'ERROR: Storage record %s is unreadable or has an unknown state.\n' "$RECORD" >&2
	printf 'ERROR: The relay will not start until the storage state is known.\n' >&2
	print_recovery
	return 1
}

main() {
	local state="none"
	[[ "$EUID" == 0 ]] || { printf 'ERROR: storage setup requires root\n' >&2; return 1; }
	# Serialize with buzz-ctl owner changes and legacy purges.
	exec 9>/run/buzz/storage-migration.lock
	flock -n 9 || return 1
	[[ ! -L "$RECORD" && ! -L "$ACTIVE" ]] || return 1
	ctl stop buzz-relay >/dev/null || return 1
	if [[ -f "$RECORD" ]]; then
		state=$(jq -er '.state | select(. == "migrated" or . == "not-needed" or . == "failed")' "$RECORD" 2>/dev/null) || {
			refuse_unreadable_record || return 1
		}
	fi
	case "$state" in
	migrated | not-needed) ;;
	failed) refuse_unmigrated "$state" || return 1 ;;
	none)
		if has_legacy_objects; then
			refuse_unmigrated "$state" || return 1
		fi
		record_not_needed || return 1
		;;
	esac
	ctl start rustfs >/dev/null || return 1
	ready http://127.0.0.1:9100/health/ready || return 1
	publish_active || return 1
	ctl start buzz-relay >/dev/null || return 1
	printf '==> Storage selection completed\n'
	return 0
}

main "$@"
