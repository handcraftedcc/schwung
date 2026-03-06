#!/usr/bin/env bash
set -euo pipefail

if ! rg -q 'build/modules/midi_fx/param_lfo/' scripts/build.sh; then
  echo "FAIL: build script missing param_lfo output path" >&2
  exit 1
fi
if ! rg -q 'src/modules/midi_fx/param_lfo/dsp/param_lfo.c' scripts/build.sh; then
  echo "FAIL: build script missing param_lfo source compile path" >&2
  exit 1
fi
if [ ! -f src/modules/midi_fx/param_lfo/module.json ]; then
  echo "FAIL: param_lfo module.json missing" >&2
  exit 1
fi

echo "PASS: param_lfo build wiring is present"
