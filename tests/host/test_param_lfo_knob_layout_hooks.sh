#!/usr/bin/env bash
set -euo pipefail

meta="src/modules/midi_fx/param_lfo/module.json"

if ! rg -q '"knobs": \["lfo1_enable", "lfo1_waveform", "lfo1_rate_hz", "lfo1_phase", "lfo1_depth", "lfo1_offset", "lfo1_polarity", "lfo1_retrigger"\]' "$meta"; then
  echo "FAIL: lfo1 knob layout is not mapped to all non-target parameters" >&2
  exit 1
fi
if ! rg -q '"knobs": \["lfo2_enable", "lfo2_waveform", "lfo2_rate_hz", "lfo2_phase", "lfo2_depth", "lfo2_offset", "lfo2_polarity", "lfo2_retrigger"\]' "$meta"; then
  echo "FAIL: lfo2 knob layout is not mapped to all non-target parameters" >&2
  exit 1
fi
if ! rg -q '"knobs": \["lfo3_enable", "lfo3_waveform", "lfo3_rate_hz", "lfo3_phase", "lfo3_depth", "lfo3_offset", "lfo3_polarity", "lfo3_retrigger"\]' "$meta"; then
  echo "FAIL: lfo3 knob layout is not mapped to all non-target parameters" >&2
  exit 1
fi
if rg -q '"knobs": \[[^]]*"lfo[1-3]_target_component"' "$meta" || rg -q '"knobs": \[[^]]*"lfo[1-3]_target_param"' "$meta"; then
  echo "FAIL: param_lfo knob layout must exclude target selection parameters" >&2
  exit 1
fi

echo "PASS: param_lfo knob layouts map non-target parameters for lfo1-lfo3"
