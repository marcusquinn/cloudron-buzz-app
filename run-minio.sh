#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

read_secret() {
	local file_path="$1"
	local value=""
	if [[ -L "$file_path" || ! -s "$file_path" ]]; then
		printf "ERROR: Required secret file is unavailable: %s\n" "$file_path" >&2
		return 1
	fi
	value=$(<"$file_path")
	printf "%s" "$value"
	return 0
}

export MINIO_ROOT_USER
MINIO_ROOT_USER=$(read_secret /app/data/config/minio-access-key)
export MINIO_ROOT_PASSWORD
MINIO_ROOT_PASSWORD=$(read_secret /app/data/config/minio-secret-key)
export MINIO_BROWSER=off
export MINIO_UPDATE=off
export HOME=/run/minio

exec /app/code/bin/minio server /app/data/minio --address 127.0.0.1:9000 --console-address 127.0.0.1:9001
