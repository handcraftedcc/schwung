#!/usr/bin/env bash
set -euo pipefail

file="src/modules/chain/dsp/chain_host.c"

if ! rg -q 'char fx_ui_hierarchy\[MAX_AUDIO_FX\]\[8192\];' "$file"; then
  echo "FAIL: missing audio FX ui_hierarchy cache storage" >&2
  exit 1
fi

if ! rg -q 'parse_ui_hierarchy_cache\(fx_dir, inst->fx_ui_hierarchy\[slot\], sizeof\(inst->fx_ui_hierarchy\[slot\]\)\);' "$file"; then
  echo "FAIL: missing audio FX ui_hierarchy parse/cache call on load" >&2
  exit 1
fi

if ! rg -q 'strcmp\(subkey, "ui_hierarchy"\) == 0 && inst->fx_count > 0' "$file"; then
  echo "FAIL: missing fx1 ui_hierarchy get route" >&2
  exit 1
fi

if ! rg -q 'strcmp\(subkey, "ui_hierarchy"\) == 0 && inst->fx_count > 1' "$file"; then
  echo "FAIL: missing fx2 ui_hierarchy get route" >&2
  exit 1
fi

if ! rg -q "inst->fx_ui_hierarchy\\[slot\\]\\[0\\] = '\\\\0';" "$file"; then
  echo "FAIL: missing fx slot ui_hierarchy clear path" >&2
  exit 1
fi

echo "PASS: chain audio FX ui_hierarchy plumbing hooks are present"
