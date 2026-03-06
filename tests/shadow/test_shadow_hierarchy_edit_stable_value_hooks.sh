#!/usr/bin/env bash
set -euo pipefail

file="src/shadow/shadow_ui.js"

if ! rg -q 'const usingStableEditVal = hierEditorEditMode &&' "$file"; then
  echo "FAIL: hierarchy draw path missing stable edit-value guard" >&2
  exit 1
fi
if ! rg -q 'hierEditorEditKey === fullKey && hierEditorEditValue !== null' "$file"; then
  echo "FAIL: hierarchy draw path is not keyed to the active edited parameter" >&2
  exit 1
fi
if ! rg -q 'const val = usingStableEditVal \? String\(hierEditorEditValue\) : getSlotParam\(hierEditorSlot, fullKey\)' "$file"; then
  echo "FAIL: hierarchy draw path still prefers live modulated values during edit mode" >&2
  exit 1
fi

echo "PASS: hierarchy editor uses stable base/edit value while editing"
