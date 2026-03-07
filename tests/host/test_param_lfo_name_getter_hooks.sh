#!/usr/bin/env bash
set -euo pipefail

midi_file="src/modules/midi_fx/param_lfo/dsp/param_lfo.c"
audio_file="src/modules/audio_fx/param_lfo_fx/param_lfo_fx.c"

if ! rg -q 'strcmp\(key, "name"\) == 0' "$midi_file"; then
  echo "FAIL: MIDI param_lfo missing name getter hook" >&2
  exit 1
fi
if ! rg -q 'strcmp\(key, "name"\) == 0' "$audio_file"; then
  echo "FAIL: Audio FX param_lfo missing name getter hook" >&2
  exit 1
fi

if ! rg -q 'return snprintf\(buf, buf_len, "Param LFO"\);' "$midi_file"; then
  echo "FAIL: MIDI param_lfo name getter does not return \"Param LFO\"" >&2
  exit 1
fi
if ! rg -q 'return snprintf\(buf, buf_len, "Param LFO"\);' "$audio_file"; then
  echo "FAIL: Audio FX param_lfo name getter does not return \"Param LFO\"" >&2
  exit 1
fi

echo "PASS: param_lfo name getter hooks return Param LFO for MIDI and Audio FX"
