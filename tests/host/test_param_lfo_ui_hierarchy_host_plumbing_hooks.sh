#!/usr/bin/env bash
set -euo pipefail

midi_file="src/modules/midi_fx/param_lfo/dsp/param_lfo.c"
audio_file="src/modules/audio_fx/param_lfo_fx/param_lfo_fx.c"

if rg -q 'build_ui_hierarchy_json\(' "$midi_file" || rg -q 'build_ui_hierarchy_json\(' "$audio_file"; then
  echo "FAIL: param_lfo plugins still contain ui_hierarchy builder helpers" >&2
  exit 1
fi

if rg -q 'strcmp\(key, "ui_hierarchy"\) == 0' "$midi_file" || rg -q 'strcmp\(key, "ui_hierarchy"\) == 0' "$audio_file"; then
  echo "FAIL: param_lfo plugins still handle ui_hierarchy in get_param" >&2
  exit 1
fi

echo "PASS: param_lfo ui_hierarchy is provided by host plumbing, not plugin getters"
