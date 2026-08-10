#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 Marcus Quinn

set -euo pipefail

export BUZZ_PAIR_RELAY_BIND_ADDR="127.0.0.1:5000"

exec /app/code/bin/buzz-pair-relay
