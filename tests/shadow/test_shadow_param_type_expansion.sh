#!/usr/bin/env bash
set -euo pipefail

shadow_file="src/shadow/shadow_ui.js"
docs_file="docs/MODULES.md"

if ! command -v rg >/dev/null 2>&1; then
  echo "rg is required to run this test" >&2
  exit 1
fi

if ! rg -F -q "function normalizeExpandedParamMeta(key, meta) {" "$shadow_file"; then
  echo "FAIL: expanded parameter metadata normalizer is missing" >&2
  exit 1
fi

if ! rg -F -q "function buildNoteParamMeta(meta) {" "$shadow_file"; then
  echo "FAIL: note type metadata builder is missing" >&2
  exit 1
fi

if ! rg -F -q "function buildRateParamMeta(meta) {" "$shadow_file"; then
  echo "FAIL: rate type metadata builder is missing" >&2
  exit 1
fi

if ! rg -F -q "function getWavPositionPreviewData(fullKey, meta) {" "$shadow_file"; then
  echo "FAIL: wav_position preview helper is missing" >&2
  exit 1
fi

if ! rg -F -q "function drawWavPositionPreview() {" "$shadow_file"; then
  echo "FAIL: wav_position preview renderer is missing" >&2
  exit 1
fi

if ! rg -F -q "function evaluateVisibilityCondition(condition, levelDef) {" "$shadow_file"; then
  echo "FAIL: visibility condition evaluator is missing" >&2
  exit 1
fi

if ! rg -F -q "function filterHierarchyParamsByVisibility(levelDef, params) {" "$shadow_file"; then
  echo "FAIL: hierarchy visibility filter is missing" >&2
  exit 1
fi

if ! rg -F -q "meta && meta.type === \"string\"" "$shadow_file"; then
  echo "FAIL: string parameter text-entry handling is missing" >&2
  exit 1
fi

if ! rg -F -q "function triggerCanvasParam(key, meta) {" "$shadow_file"; then
  echo "FAIL: canvas trigger handler is missing" >&2
  exit 1
fi

if ! rg -F -q "meta && meta.type === \"canvas\"" "$shadow_file"; then
  echo "FAIL: canvas parameter handling is missing" >&2
  exit 1
fi

if ! rg -F -q "| \`note\` | \`mode\`, \`min_note\`, \`max_note\` |" "$docs_file"; then
  echo "FAIL: docs/MODULES.md is missing note parameter type documentation" >&2
  exit 1
fi

if ! rg -F -q "| \`wav_position\` | \`display_unit\`, \`mode\`, \`filepath_param\`, \`min\`, \`max\`, \`step\` |" "$docs_file"; then
  echo "FAIL: docs/MODULES.md is missing wav_position parameter type documentation" >&2
  exit 1
fi

if ! rg -F -q "Supported condition fields:" "$docs_file"; then
  echo "FAIL: docs/MODULES.md is missing visible_if condition guidance" >&2
  exit 1
fi

echo "PASS: expanded shadow parameter type plumbing present"
exit 0
