#!/usr/bin/env bash
set -euo pipefail

file="src/modules/chain/dsp/chain_host.c"

if ! rg -q 'static int chain_param_key_matches\(' "$file"; then
  echo "FAIL: missing chain_param_key_matches helper for modulation key matching" >&2
  exit 1
fi
if ! rg -q '\*\(suffix - 1\) != '\''_'\''' "$file"; then
  echo "FAIL: child-prefix key matching delimiter check is missing" >&2
  exit 1
fi
if ! rg -q 'has_digit = 1' "$file"; then
  echo "FAIL: child-prefix key matching does not require an indexed prefix" >&2
  exit 1
fi
if ! rg -q 'chain_param_key_matches\(key, inst->synth_params\[i\]\.key\)' "$file"; then
  echo "FAIL: synth modulation metadata lookup is not using child-prefix matching" >&2
  exit 1
fi

echo "PASS: chain modulation metadata lookup supports child-prefixed parameter keys"
