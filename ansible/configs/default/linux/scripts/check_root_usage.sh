#!/usr/bin/env bash
set -euo pipefail

# Print root filesystem usage as an integer percentage for Zabbix.
df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }'
