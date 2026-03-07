#!/usr/bin/env bash
set -euo pipefail

midi_file="src/modules/midi_fx/param_lfo/dsp/param_lfo.c"
audio_file="src/modules/audio_fx/param_lfo_fx/param_lfo_fx.c"

extract_shared() {
  local src="$1"
  local dst="$2"
  awk '
    /\/\* === PARAM_LFO_SHARED_BEGIN === \*\// { in_block=1 }
    in_block { print }
    /\/\* === PARAM_LFO_SHARED_END === \*\// { in_block=0 }
  ' "$src" > "$dst"
}

if ! rg -q 'PARAM_LFO_SHARED_BEGIN' "$midi_file" || ! rg -q 'PARAM_LFO_SHARED_END' "$midi_file"; then
  echo "FAIL: missing shared block markers in MIDI param_lfo source" >&2
  exit 1
fi
if ! rg -q 'PARAM_LFO_SHARED_BEGIN' "$audio_file" || ! rg -q 'PARAM_LFO_SHARED_END' "$audio_file"; then
  echo "FAIL: missing shared block markers in Audio FX param_lfo source" >&2
  exit 1
fi

tmp_a="$(mktemp)"
tmp_b="$(mktemp)"
trap 'rm -f "$tmp_a" "$tmp_b"' EXIT

extract_shared "$midi_file" "$tmp_a"
extract_shared "$audio_file" "$tmp_b"

if ! diff -u "$tmp_a" "$tmp_b" >/dev/null; then
  echo "FAIL: shared param_lfo core drifted between MIDI and Audio FX variants" >&2
  exit 1
fi

echo "PASS: shared param_lfo core is identical in MIDI and Audio FX variants"
