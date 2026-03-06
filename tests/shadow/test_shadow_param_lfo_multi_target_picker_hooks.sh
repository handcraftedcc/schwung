#!/usr/bin/env bash
set -euo pipefail

file="src/shadow/shadow_ui.js"

if ! rg -q 'endsWith\("_target_component"\)' "$file"; then
  echo "FAIL: param_lfo picker does not recognize suffixed target_component keys" >&2
  exit 1
fi
if ! rg -q 'endsWith\("_target_param"\)' "$file"; then
  echo "FAIL: param_lfo picker does not recognize suffixed target_param keys" >&2
  exit 1
fi
if ! rg -q 'paramLfoPickerTargetComponentKey' "$file"; then
  echo "FAIL: picker is missing dynamic target_component key tracking" >&2
  exit 1
fi
if ! rg -q 'paramLfoPickerTargetParamKey' "$file"; then
  echo "FAIL: picker is missing dynamic target_param key tracking" >&2
  exit 1
fi

echo "PASS: shadow param_lfo picker supports multi-LFO suffixed target keys"
