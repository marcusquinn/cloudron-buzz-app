#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

readonly RUN_DIR="/run/buzz"
readonly MINIO_ENDPOINT="http://127.0.0.1:9000"
readonly S3_BUCKET="buzz-data"
readonly FEATURE_ENABLED="true"

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

read_secret() {
	local file_path="$1"
	local label="$2"
	local value=""
	if [[ -L "$file_path" || ! -s "$file_path" ]]; then
		fail "${label} file is unavailable" || return 1
	fi
	value=$(<"$file_path")
	printf "%s" "$value"
	return 0
}

validate_service_urls() {
	case "${CLOUDRON_POSTGRESQL_URL:-}" in
	postgres://* | postgresql://*) ;;
	*) fail "CLOUDRON_POSTGRESQL_URL is missing or invalid" || return 1 ;;
	esac
	case "${CLOUDRON_REDIS_URL:-}" in
	redis://* | rediss://*) ;;
	*) fail "CLOUDRON_REDIS_URL is missing or invalid" || return 1 ;;
	esac
	return 0
}

ensure_minio_bucket() {
	local attempt=0
	local max_attempts=90

	while ((attempt < max_attempts)); do
		if curl --fail --silent --show-error "${MINIO_ENDPOINT}/minio/health/ready" >/dev/null 2>&1; then
			break
		fi
		((attempt += 1))
		sleep 1
	done
	if ((attempt >= max_attempts)); then
		fail "MinIO did not become ready within ${max_attempts} seconds" || return 1
	fi

	if ! MC_CONFIG_DIR="${RUN_DIR}/mc" /app/code/bin/mc alias set cloudron "$MINIO_ENDPOINT" "$BUZZ_S3_ACCESS_KEY" "$BUZZ_S3_SECRET_KEY" --api S3v4 >/dev/null 2>&1; then
		fail "Could not configure the local MinIO client" || return 1
	fi
	if ! MC_CONFIG_DIR="${RUN_DIR}/mc" /app/code/bin/mc mb --ignore-existing "cloudron/${S3_BUCKET}" >/dev/null 2>&1; then
		fail "Could not create the private Buzz object-storage bucket" || return 1
	fi
	if ! MC_CONFIG_DIR="${RUN_DIR}/mc" /app/code/bin/mc anonymous set none "cloudron/${S3_BUCKET}" >/dev/null 2>&1; then
		fail "Could not enforce the private Buzz bucket policy" || return 1
	fi
	return 0
}

main() {
	local relay_private_key=""
	local owner_public_key=""
	local git_hook_secret=""
	local minio_access_key=""
	local minio_secret_key=""

	validate_service_urls || return 1
	relay_private_key=$(read_secret /app/data/config/relay-private-key "relay private key") || return 1
	owner_public_key=$(read_secret /app/data/config/owner-public-key "owner public key") || return 1
	git_hook_secret=$(read_secret /app/data/config/git-hook-hmac-secret "Git hook HMAC secret") || return 1
	minio_access_key=$(read_secret /app/data/config/minio-access-key "MinIO access key") || return 1
	minio_secret_key=$(read_secret /app/data/config/minio-secret-key "MinIO secret key") || return 1

	export DATABASE_URL="${CLOUDRON_POSTGRESQL_URL}"
	export REDIS_URL="${CLOUDRON_REDIS_URL}"
	export RELAY_URL="wss://${CLOUDRON_APP_DOMAIN}"
	export BUZZ_PAIRING_RELAY_URL="wss://${CLOUDRON_APP_DOMAIN}/pair"
	export BUZZ_BIND_ADDR="127.0.0.1:3001"
	export BUZZ_HEALTH_PORT="8080"
	export BUZZ_METRICS_PORT="9102"
	export BUZZ_RELAY_PRIVATE_KEY="$relay_private_key"
	export RELAY_OWNER_PUBKEY="$owner_public_key"
	export BUZZ_REQUIRE_AUTH_TOKEN="$FEATURE_ENABLED"
	export BUZZ_REQUIRE_RELAY_MEMBERSHIP="$FEATURE_ENABLED"
	export BUZZ_ALLOW_NIP_OA_AUTH="$FEATURE_ENABLED"
	export BUZZ_CORS_ORIGINS="https://${CLOUDRON_APP_DOMAIN},tauri://localhost,http://tauri.localhost,https://tauri.localhost"
	export BUZZ_AUTO_MIGRATE="$FEATURE_ENABLED"
	export BUZZ_AUDIT_ENABLED="$FEATURE_ENABLED"
	export BUZZ_REQUIRE_MEDIA_GET_AUTH="$FEATURE_ENABLED"
	export BUZZ_HUDDLE_AUDIO_AVAILABLE="$FEATURE_ENABLED"
	export BUZZ_MESH="off"
	export BUZZ_SERVE_GIT_WEB_GUI="$FEATURE_ENABLED"
	export BUZZ_WEB_DIR="/srv/buzz/web"
	export BUZZ_ADMIN_WEB_DIR="/srv/buzz/admin-web"
	export BUZZ_PUSH_GATEWAY_DELIVERY_URL=""
	export BUZZ_USAGE_METRICS_PER_COMMUNITY="off"
	export BUZZ_GIT_REPO_PATH="${RUN_DIR}/git-repos"
	export BUZZ_GIT_PACK_CACHE_PATH="${RUN_DIR}/git-pack-cache"
	export BUZZ_GIT_PACK_CACHE_MAX_BYTES="1073741824"
	export BUZZ_GIT_HOOK_HMAC_SECRET="$git_hook_secret"
	export BUZZ_GIT_CONFORMANCE_PROBE="$FEATURE_ENABLED"
	export BUZZ_S3_ENDPOINT="$MINIO_ENDPOINT"
	export BUZZ_S3_ACCESS_KEY="$minio_access_key"
	export BUZZ_S3_SECRET_KEY="$minio_secret_key"
	export BUZZ_S3_BUCKET="$S3_BUCKET"
	export BUZZ_S3_REGION="us-east-1"
	export BUZZ_MEDIA_BASE_URL="https://${CLOUDRON_APP_DOMAIN}/media"
	export RUST_LOG="${RUST_LOG:-buzz_relay=info,buzz_db=info,buzz_media=info}"
	export HOME="$RUN_DIR"

	ensure_minio_bucket || return 1
	log "Launching Buzz relay at wss://${CLOUDRON_APP_DOMAIN}"
	return 0
}

main "$@"
exec /app/code/bin/buzz-relay
