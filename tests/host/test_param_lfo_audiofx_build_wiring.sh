#!/usr/bin/env bash
set -euo pipefail

if ! rg -q 'build/modules/audio_fx/param_lfo_fx/' scripts/build.sh; then
  echo "FAIL: build script missing param_lfo_fx audio FX output path" >&2
  exit 1
fi
if ! rg -q 'src/modules/audio_fx/param_lfo_fx/param_lfo_fx.c' scripts/build.sh; then
  echo "FAIL: build script missing param_lfo_fx audio FX source compile path" >&2
  exit 1
fi

meta="src/modules/audio_fx/param_lfo_fx/module.json"
if [ ! -f "$meta" ]; then
  echo "FAIL: param_lfo_fx module.json missing" >&2
  exit 1
fi
if ! rg -q '"id": "param_lfo_fx"' "$meta"; then
  echo "FAIL: param_lfo_fx module id mismatch" >&2
  exit 1
fi
if ! rg -q '"component_type": "audio_fx"' "$meta"; then
  echo "FAIL: param_lfo_fx must declare audio_fx component type" >&2
  exit 1
fi

echo "PASS: param_lfo_fx audio FX build wiring is present"
