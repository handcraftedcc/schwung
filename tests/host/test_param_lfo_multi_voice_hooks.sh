#!/usr/bin/env bash
set -euo pipefail

file="src/modules/midi_fx/param_lfo/dsp/param_lfo.c"
meta="src/modules/midi_fx/param_lfo/module.json"

if ! rg -q '#define PARAM_LFO_COUNT 3' "$file"; then
  echo "FAIL: param_lfo does not define 3 modulation lanes" >&2
  exit 1
fi
if ! rg -q 'for \(int i = 0; i < PARAM_LFO_COUNT; i\+\+\)' "$file"; then
  echo "FAIL: param_lfo is not iterating across all modulation lanes" >&2
  exit 1
fi
if ! rg -q 'lfo%d_target_param' "$file"; then
  echo "FAIL: param_lfo state/metadata does not expose per-LFO target params" >&2
  exit 1
fi
if ! rg -q '"level": "lfo1"' "$meta" || ! rg -q '"level": "lfo3"' "$meta"; then
  echo "FAIL: param_lfo ui_hierarchy root missing lfo1-lfo3 submenus" >&2
  exit 1
fi
if ! rg -q '"key": "lfo1_enable"' "$meta" || ! rg -q '"key": "lfo3_enable"' "$meta"; then
  echo "FAIL: param_lfo metadata missing per-LFO parameter keys" >&2
  exit 1
fi

echo "PASS: param_lfo exposes 3 independent global LFO lanes in DSP + module metadata"
