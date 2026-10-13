#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn
set -euo pipefail

# RustFS 1.0.1 rustfs/src/config/cli.rs supports file-based credentials.
# Never pass credentials in process arguments or enable the public console.
for secret_file in /app/data/config/rustfs-access-key /app/data/config/rustfs-secret-key; do
	if [[ -L "$secret_file" || ! -s "$secret_file" ]]; then
		printf 'ERROR: RustFS credential file is unavailable\n' >&2
		exit 1
	fi
done
export RUSTFS_ACCESS_KEY_FILE=/app/data/config/rustfs-access-key
export RUSTFS_SECRET_KEY_FILE=/app/data/config/rustfs-secret-key
export RUSTFS_CONSOLE_ENABLE=false
export RUSTFS_ADDRESS=127.0.0.1:9100
export RUSTFS_VOLUMES=/app/data/rustfs
export HOME=/run/buzz
exec /app/code/bin/rustfs server /app/data/rustfs
