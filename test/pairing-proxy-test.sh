#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

readonly IMAGE="${1:-cloudron-buzz-app:test}"

docker image inspect "$IMAGE" >/dev/null
docker run --rm --interactive --platform linux/amd64 --entrypoint /bin/bash "$IMAGE" -s <<'CONTAINER'
set -euo pipefail

mkdir -p /run/buzz/nginx/{client-body,fastcgi,proxy,scgi,uwsgi}
chown -R cloudron:cloudron /run/buzz

gosu cloudron:cloudron /app/code/bin/buzz-pair-relay >/run/buzz/pairing-test.log 2>&1 &
pairing_pid=$!
gosu cloudron:cloudron python3 -m http.server 3001 --bind 127.0.0.1 >/run/buzz/main-test.log 2>&1 &
main_pid=$!
gosu cloudron:cloudron nginx -c /app/code/nginx.conf -g "daemon off;" &
nginx_pid=$!
trap 'kill "$nginx_pid" "$main_pid" "$pairing_pid" 2>/dev/null || true' EXIT
sleep 1

main_status=$(curl --silent --output /dev/null --write-out "%{http_code}" http://127.0.0.1:3000/)
[[ "$main_status" == "200" ]]

post_status=$(curl --silent --output /dev/null --write-out "%{http_code}" --request POST http://127.0.0.1:3000/pair)
[[ "$post_status" == "403" ]]

set +e
pairing_response=$(curl --silent --include --no-buffer --max-time 1 --http1.1 \
	--header "Connection: Upgrade" \
	--header "Upgrade: websocket" \
	--header "Sec-WebSocket-Version: 13" \
	--header "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
	http://127.0.0.1:3000/pair)
pairing_status=$?
set -e
[[ "$pairing_status" -eq 0 || "$pairing_status" -eq 28 ]]
[[ "$pairing_response" == *"101 Switching Protocols"* ]]

set +e
wrong_path_response=$(curl --silent --include --no-buffer --max-time 1 --http1.1 \
	--header "Connection: Upgrade" \
	--header "Upgrade: websocket" \
	--header "Sec-WebSocket-Version: 13" \
	--header "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
	http://127.0.0.1:3000/pair/)
wrong_path_status=$?
set -e
[[ "$wrong_path_status" -eq 0 ]]
[[ "$wrong_path_response" != *"101 Switching Protocols"* ]]

printf "PASS: main route %s, pairing POST guard %s, exact pairing WebSocket 101\n" "$main_status" "$post_status"
CONTAINER
