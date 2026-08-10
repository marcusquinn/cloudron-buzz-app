#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

readonly CONFIG_DIR="/app/data/config"
readonly MINIO_DATA_DIR="/app/data/minio"
readonly RUN_DIR="/run/buzz"
readonly RELAY_PRIVATE_KEY_FILE="${CONFIG_DIR}/relay-private-key"
readonly RELAY_PUBLIC_KEY_FILE="${CONFIG_DIR}/relay-public-key"
readonly OWNER_PUBLIC_KEY_FILE="${CONFIG_DIR}/owner-public-key"
readonly MINIO_ACCESS_KEY_FILE="${CONFIG_DIR}/minio-access-key"
readonly MINIO_SECRET_KEY_FILE="${CONFIG_DIR}/minio-secret-key"
readonly GIT_HOOK_SECRET_FILE="${CONFIG_DIR}/git-hook-hmac-secret"

log() {
	local message="$1"
	printf "==> %s\n" "$message"
	return 0
}

fail() {
	local message="$1"
	printf "ERROR: %s\n" "$message" >&2
	return 1
}

require_env() {
	local variable_name="$1"
	if [[ -z "${!variable_name:-}" ]]; then
		fail "Required Cloudron environment variable ${variable_name} is not set" || return 1
	fi
	return 0
}

ensure_real_directory() {
	local directory_path="$1"
	local directory_mode="$2"
	if [[ -L "$directory_path" ]]; then
		fail "Refusing symlinked directory: ${directory_path}" || return 1
	fi
	if [[ -e "$directory_path" && ! -d "$directory_path" ]]; then
		fail "Expected a directory: ${directory_path}" || return 1
	fi
	mkdir -p "$directory_path"
	chmod "$directory_mode" "$directory_path"
	return 0
}

assert_regular_file() {
	local file_path="$1"
	local label="$2"
	if [[ -L "$file_path" || ! -f "$file_path" ]]; then
		fail "${label} must be a regular file: ${file_path}" || return 1
	fi
	return 0
}

write_secure_value() {
	local file_path="$1"
	local value="$2"
	local temporary_file=""

	if [[ -L "$file_path" ]]; then
		fail "Refusing symlinked secret file: ${file_path}" || return 1
	fi
	temporary_file=$(mktemp "${file_path}.tmp.XXXXXX") || return 1
	chmod 0600 "$temporary_file"
	printf "%s\n" "$value" >"$temporary_file"
	mv -f "$temporary_file" "$file_path"
	return 0
}

generate_secret() {
	local file_path="$1"
	local byte_count="$2"
	local label="$3"
	local generated_value=""

	if [[ -s "$file_path" ]]; then
		assert_regular_file "$file_path" "$label" || return 1
		chmod 0600 "$file_path"
		return 0
	fi
	if [[ -e "$file_path" && ! -f "$file_path" ]]; then
		fail "${label} is not a regular file: ${file_path}" || return 1
	fi
	generated_value=$(openssl rand -hex "$byte_count") || {
		fail "Failed to generate ${label}" || return 1
	}
	write_secure_value "$file_path" "$generated_value" || return 1
	log "Generated ${label}"
	return 0
}

validate_hex_key_file() {
	local file_path="$1"
	local label="$2"
	local value=""

	assert_regular_file "$file_path" "$label" || return 1
	value=$(<"$file_path")
	if [[ ! "$value" =~ ^[0-9a-f]{64}$ ]]; then
		fail "${label} must contain exactly 64 lowercase hexadecimal characters" || return 1
	fi
	return 0
}

initialize_relay_identity() {
	local key_output=""
	local line=""
	local public_key=""
	local private_key=""

	if [[ -e "$RELAY_PRIVATE_KEY_FILE" || -e "$RELAY_PUBLIC_KEY_FILE" ]]; then
		if [[ ! -s "$RELAY_PRIVATE_KEY_FILE" || ! -s "$RELAY_PUBLIC_KEY_FILE" ]]; then
			fail "Relay identity is incomplete; refusing to rotate a partially persisted identity" || return 1
		fi
		validate_hex_key_file "$RELAY_PRIVATE_KEY_FILE" "relay private key" || return 1
		validate_hex_key_file "$RELAY_PUBLIC_KEY_FILE" "relay public key" || return 1
		return 0
	fi

	key_output=$(/app/code/bin/buzz-admin generate-key) || {
		fail "buzz-admin could not generate the relay identity" || return 1
	}
	while IFS= read -r line; do
		if [[ "$line" =~ ^Public[[:space:]]key:[[:space:]]+([0-9a-f]{64})$ ]]; then
			public_key="${BASH_REMATCH[1]}"
		elif [[ "$line" =~ ^Secret[[:space:]]key:[[:space:]]+([0-9a-f]{64})$ ]]; then
			private_key="${BASH_REMATCH[1]}"
		fi
	done <<<"$key_output"
	unset key_output

	if [[ -z "$public_key" || -z "$private_key" ]]; then
		fail "buzz-admin returned an unexpected key-generation response" || return 1
	fi
	write_secure_value "$RELAY_PRIVATE_KEY_FILE" "$private_key" || return 1
	write_secure_value "$RELAY_PUBLIC_KEY_FILE" "$public_key" || return 1
	unset private_key
	log "Generated stable Buzz relay identity"
	return 0
}

initialize_owner() {
	local relay_public_key=""

	if [[ ! -e "$OWNER_PUBLIC_KEY_FILE" ]]; then
		relay_public_key=$(<"$RELAY_PUBLIC_KEY_FILE")
		write_secure_value "$OWNER_PUBLIC_KEY_FILE" "$relay_public_key" || return 1
		log "Set the relay identity as the bootstrap owner"
	fi
	validate_hex_key_file "$OWNER_PUBLIC_KEY_FILE" "owner public key" || return 1
	return 0
}

main() {
	local required_variable=""
	local app_domain=""

	log "Starting Buzz for Cloudron"
	for required_variable in CLOUDRON_APP_DOMAIN CLOUDRON_POSTGRESQL_URL CLOUDRON_REDIS_URL; do
		require_env "$required_variable" || return 1
	done

	app_domain="${CLOUDRON_APP_DOMAIN}"
	if [[ ! "$app_domain" =~ ^[A-Za-z0-9.-]+$ || "$app_domain" == *..* ]]; then
		fail "CLOUDRON_APP_DOMAIN contains unexpected characters" || return 1
	fi

	ensure_real_directory "$CONFIG_DIR" 0700 || return 1
	ensure_real_directory "$MINIO_DATA_DIR" 0750 || return 1
	ensure_real_directory "$RUN_DIR" 0750 || return 1
	ensure_real_directory "${RUN_DIR}/git-repos" 0750 || return 1
	ensure_real_directory "${RUN_DIR}/git-pack-cache" 0750 || return 1
	ensure_real_directory "${RUN_DIR}/mc" 0700 || return 1
	ensure_real_directory "${RUN_DIR}/nginx" 0750 || return 1
	ensure_real_directory "${RUN_DIR}/nginx/client-body" 0750 || return 1
	ensure_real_directory "${RUN_DIR}/nginx/fastcgi" 0750 || return 1
	ensure_real_directory "${RUN_DIR}/nginx/proxy" 0750 || return 1
	ensure_real_directory "${RUN_DIR}/nginx/scgi" 0750 || return 1
	ensure_real_directory "${RUN_DIR}/nginx/uwsgi" 0750 || return 1
	ensure_real_directory "/run/minio" 0750 || return 1
	ensure_real_directory "/run/supervisor" 0750 || return 1

	generate_secret "$MINIO_ACCESS_KEY_FILE" 16 "MinIO access key" || return 1
	generate_secret "$MINIO_SECRET_KEY_FILE" 32 "MinIO secret key" || return 1
	generate_secret "$GIT_HOOK_SECRET_FILE" 32 "Git hook HMAC secret" || return 1
	initialize_relay_identity || return 1
	initialize_owner || return 1

	chown -hR cloudron:cloudron "$CONFIG_DIR" "$MINIO_DATA_DIR" "$RUN_DIR" /run/minio /run/supervisor
	chmod 0600 "$MINIO_ACCESS_KEY_FILE" "$MINIO_SECRET_KEY_FILE" "$GIT_HOOK_SECRET_FILE" "$RELAY_PRIVATE_KEY_FILE" "$RELAY_PUBLIC_KEY_FILE" "$OWNER_PUBLIC_KEY_FILE"

	if [[ -L /app/data/.initialized ]]; then
		fail "Refusing symlinked initialization marker" || return 1
	fi
	touch /app/data/.initialized
	chown -h cloudron:cloudron /app/data/.initialized
	return 0
}

main "$@"
exec /usr/bin/supervisord --configuration /app/code/supervisord.conf --nodaemon
