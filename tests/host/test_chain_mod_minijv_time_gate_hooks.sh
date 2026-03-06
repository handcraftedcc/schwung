#!/usr/bin/env bash
set -euo pipefail

file="src/modules/chain/dsp/chain_host.c"

if ! rg -q '#define MOD_MINIJV_INT_MIN_INTERVAL_MS 50' "$file"; then
  echo "FAIL: missing Mini-JV int modulation min-interval constant" >&2
  exit 1
fi
if ! rg -q 'uint64_t last_applied_ms;' "$file"; then
  echo "FAIL: modulation target state missing last_applied_ms timestamp" >&2
  exit 1
fi
if ! rg -q 'get_time_ms\(\)' "$file"; then
  echo "FAIL: modulation path is not using monotonic time for gating" >&2
  exit 1
fi
if ! rg -q 'if \(entry->last_applied_ms > 0 && \(now_ms - entry->last_applied_ms\) < min_interval_ms\)' "$file"; then
  echo "FAIL: missing Mini-JV time-based modulation throttle guard" >&2
  exit 1
fi

echo "PASS: chain modulation includes Mini-JV time-based rate limiting"
