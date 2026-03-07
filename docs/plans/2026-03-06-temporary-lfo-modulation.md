# Temporary LFO Core Modulation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a non-destructive, runtime modulation layer to Signal Chain so an LFO source can modulate target parameters without overwriting persisted base values.

**Architecture:** Extend chain core (`chain_host.c`) with a modulation bus and base/effective value cache, expose modulation publish callbacks through `host_api_v1_t`, and ship a built-in `param_lfo` MIDI FX module that publishes modulation samples into that bus. Reuse Shadow UI picker logic so users can assign local-chain targets from existing target discovery paths.

**Tech Stack:** C (chain DSP + MIDI FX module), QuickJS Shadow UI JavaScript, shell regression tests.

---

### Task 1: Add Host API Modulation Callback Surface

**Files:**
- Modify: `src/host/plugin_api_v1.h`
- Modify: `src/modules/chain/dsp/chain_host.c`
- Test: `tests/host/test_chain_mod_host_api_surface.sh`

**Step 1: Write failing regression test for host API fields**

Create `tests/host/test_chain_mod_host_api_surface.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

file_api="src/host/plugin_api_v1.h"
file_chain="src/modules/chain/dsp/chain_host.c"

rg -q 'mod_emit_value' "$file_api"
rg -q 'mod_clear_source' "$file_api"
rg -q 'mod_host_ctx' "$file_api"
rg -q 'inst->subplugin_host_api.mod_emit_value' "$file_chain"
```

**Step 2: Run test and verify it fails**

Run: `bash tests/host/test_chain_mod_host_api_surface.sh`
Expected: FAIL because fields are not yet defined.

**Step 3: Implement API extension**

In `src/host/plugin_api_v1.h`, append callback fields to `host_api_v1_t` (end of struct):

```c
typedef int (*move_mod_emit_value_fn)(void *ctx,
    const char *source_id,
    const char *target,
    const char *param,
    float signal,
    float depth,
    float offset,
    int bipolar,
    int enabled);

typedef void (*move_mod_clear_source_fn)(void *ctx, const char *source_id);

move_mod_emit_value_fn mod_emit_value;
move_mod_clear_source_fn mod_clear_source;
void *mod_host_ctx;
```

In `chain_host.c`, wire these fields in both v1 global host copies and v2 per-instance host copies.

**Step 4: Run test to verify pass**

Run: `bash tests/host/test_chain_mod_host_api_surface.sh`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/host/plugin_api_v1.h src/modules/chain/dsp/chain_host.c tests/host/test_chain_mod_host_api_surface.sh
git commit -m "feat(chain): add modulation callback surface to host API"
```

### Task 2: Implement Core Modulation Runtime State in Chain Host

**Files:**
- Modify: `src/modules/chain/dsp/chain_host.c`
- Test: `tests/host/test_chain_mod_runtime_state.sh`

**Step 1: Write failing test for runtime state/hooks presence**

Create `tests/host/test_chain_mod_runtime_state.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
file="src/modules/chain/dsp/chain_host.c"

rg -q 'typedef struct mod_target_state' "$file"
rg -q 'mod_target_state_t mod_targets' "$file"
rg -q 'static int chain_mod_emit_value' "$file"
rg -q 'static void chain_mod_clear_source' "$file"
```

**Step 2: Run test and confirm failure**

Run: `bash tests/host/test_chain_mod_runtime_state.sh`
Expected: FAIL.

**Step 3: Add runtime structs and helper functions**

Add to `chain_host.c`:
- `mod_target_state_t` with fields for target key, base, effective, contribution, min/max/type, active flag, source id.
- `mod_source_state_t` for source metadata.
- fixed-size arrays in `chain_instance_t`.
- helper functions to lookup/create target entries and clamp numeric values.

**Step 4: Run test to verify pass**

Run: `bash tests/host/test_chain_mod_runtime_state.sh`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/modules/chain/dsp/chain_host.c tests/host/test_chain_mod_runtime_state.sh
git commit -m "feat(chain): add modulation runtime state model"
```

### Task 3: Apply Base vs Effective Semantics in v2_set_param/v2_get_param

**Files:**
- Modify: `src/modules/chain/dsp/chain_host.c`
- Test: `tests/host/test_chain_mod_base_effective_semantics.sh`

**Step 1: Add failing test for semantic hooks**

Create `tests/host/test_chain_mod_base_effective_semantics.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
file="src/modules/chain/dsp/chain_host.c"

rg -q 'chain_mod_update_base_from_set_param' "$file"
rg -q 'chain_mod_apply_effective_value' "$file"
rg -q 'if \(chain_mod_is_target_active' "$file"
```

**Step 2: Run test and verify failure**

Run: `bash tests/host/test_chain_mod_base_effective_semantics.sh`
Expected: FAIL.

**Step 3: Implement base/effective routing**

In `v2_set_param`:
- For modulated numeric targets, update base cache.
- Recompute and send effective value to sub-plugin.
- For non-modulated targets, keep current behavior.

In `v2_get_param`:
- Continue returning plugin/base values for normal operations.
- Add optional debug key (`mod_state_json`) for diagnostics (safe internal visibility).

**Step 4: Run test to verify pass**

Run: `bash tests/host/test_chain_mod_base_effective_semantics.sh`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/modules/chain/dsp/chain_host.c tests/host/test_chain_mod_base_effective_semantics.sh
git commit -m "feat(chain): enforce non-destructive base/effective modulation semantics"
```

### Task 4: Wire Modulation Callback Handlers for All Sub-Plugins

**Files:**
- Modify: `src/modules/chain/dsp/chain_host.c`
- Test: `tests/host/test_chain_mod_slot_agnostic_wiring.sh`

**Step 1: Add failing wiring test**

Create `tests/host/test_chain_mod_slot_agnostic_wiring.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
file="src/modules/chain/dsp/chain_host.c"

rg -q 'inst->subplugin_host_api.mod_emit_value = chain_mod_emit_value' "$file"
rg -q 'inst->subplugin_host_api.mod_clear_source = chain_mod_clear_source' "$file"
rg -q 'inst->subplugin_host_api.mod_host_ctx = inst' "$file"
rg -q 'g_subplugin_host_api.mod_emit_value = chain_mod_emit_value' "$file"
```

**Step 2: Run test and confirm failure**

Run: `bash tests/host/test_chain_mod_slot_agnostic_wiring.sh`
Expected: FAIL.

**Step 3: Implement callback wiring in init paths**

Update:
- `move_plugin_init_v1` host copies
- `v2_create_instance` instance host copies

Ensure callbacks operate with instance context and are valid for MIDI FX and Audio FX sub-plugins.

**Step 4: Run test and verify pass**

Run: `bash tests/host/test_chain_mod_slot_agnostic_wiring.sh`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/modules/chain/dsp/chain_host.c tests/host/test_chain_mod_slot_agnostic_wiring.sh
git commit -m "feat(chain): wire slot-agnostic modulation callbacks for sub-plugins"
```

### Task 5: Add Built-In Param LFO MIDI FX Module

**Files:**
- Create: `src/modules/midi_fx/param_lfo/module.json`
- Create: `src/modules/midi_fx/param_lfo/dsp/param_lfo.c`
- Modify: `scripts/build.sh`
- Test: `tests/host/test_param_lfo_build_wiring.sh`

**Step 1: Write failing build-wiring test**

Create `tests/host/test_param_lfo_build_wiring.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

rg -q 'build/modules/midi_fx/param_lfo/' scripts/build.sh
rg -q 'src/modules/midi_fx/param_lfo/dsp/param_lfo.c' scripts/build.sh
test -f src/modules/midi_fx/param_lfo/module.json
```

**Step 2: Run and verify fail**

Run: `bash tests/host/test_param_lfo_build_wiring.sh`
Expected: FAIL.

**Step 3: Create module files and compile target**

`module.json` should expose `component_type: "midi_fx"`, `chainable: true`, `ui_hierarchy` + `chain_params` including:
- waveform
- rate_hz
- depth
- offset
- polarity
- enable
- target_component
- target_param

Implement `param_lfo.c`:
- maintain phase/rate/waveform state
- on `tick`, emit modulation via `host->mod_emit_value(...)`
- on disable/unload, call `host->mod_clear_source(...)`
- implement `get_param("state")` / `set_param("state")`

**Step 4: Run test to verify pass**

Run: `bash tests/host/test_param_lfo_build_wiring.sh`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/modules/midi_fx/param_lfo scripts/build.sh tests/host/test_param_lfo_build_wiring.sh
git commit -m "feat(midi-fx): add built-in param_lfo module and build wiring"
```

### Task 6: Reuse Shadow UI Target Picker for Param LFO Target Assignment

**Files:**
- Modify: `src/shadow/shadow_ui.js`
- Test: `tests/shadow/test_shadow_param_lfo_target_picker.sh`

**Step 1: Add failing UI integration test**

Create `tests/shadow/test_shadow_param_lfo_target_picker.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
file="src/shadow/shadow_ui.js"

rg -q 'param_lfo' "$file"
rg -q 'target_param' "$file"
rg -q 'getKnobTargets\(' "$file"
rg -q 'getKnobParamsForTarget\(' "$file"
```

**Step 2: Run test and confirm failure**

Run: `bash tests/shadow/test_shadow_param_lfo_target_picker.sh`
Expected: FAIL.

**Step 3: Implement picker bridge**

In `shadow_ui.js` hierarchy/component edit flow:
- detect when editing Param LFO target fields
- open existing target picker path (same discovery logic used for knob mapping)
- write selected target back into LFO params (`target_component`, `target_param`)
- enforce same-chain and numeric-only filters in picker result handling

**Step 4: Run test and verify pass**

Run: `bash tests/shadow/test_shadow_param_lfo_target_picker.sh`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/shadow/shadow_ui.js tests/shadow/test_shadow_param_lfo_target_picker.sh
git commit -m "feat(shadow-ui): integrate param_lfo target picker with existing mapping discovery"
```

### Task 7: Add Save/Load Regression Coverage for Non-Destructive Modulation

**Files:**
- Create: `tests/shadow/test_param_lfo_no_baked_target_values.sh`
- Create: `tests/host/test_chain_mod_clear_restores_base.sh`
- Modify: `src/modules/chain/dsp/chain_host.c` (if needed)

**Step 1: Write failing regression tests**

`test_chain_mod_clear_restores_base.sh` should assert modulation clear path exists and reapplies base.

`test_param_lfo_no_baked_target_values.sh` should assert save path still relies on target plugin `state` + `knob_mappings`, not transient modulation cache keys.

**Step 2: Run tests and verify failures**

Run:
- `bash tests/host/test_chain_mod_clear_restores_base.sh`
- `bash tests/shadow/test_param_lfo_no_baked_target_values.sh`

Expected: FAIL initially.

**Step 3: Implement/fix any missing restore semantics**

In `chain_host.c`:
- ensure `chain_mod_clear_source` reapplies base values
- ensure unload paths clear source contributions

**Step 4: Run tests and verify pass**

Run both scripts again.
Expected: PASS.

**Step 5: Commit**

```bash
git add src/modules/chain/dsp/chain_host.c tests/host/test_chain_mod_clear_restores_base.sh tests/shadow/test_param_lfo_no_baked_target_values.sh
git commit -m "test(chain): cover modulation clear and non-destructive save semantics"
```

### Task 8: Documentation + End-to-End Verification

**Files:**
- Modify: `docs/MODULES.md`
- Modify: `docs/API.md`
- Modify: `CLAUDE.md`
- Modify: `MANUAL.md` (if user-facing workflow changed)

**Step 1: Update docs for new core modulation support**

Document:
- new host modulation callback fields in API
- `param_lfo` built-in module and constraints
- same-chain numeric target restrictions
- slot-agnostic core support (MIDI FX now, Audio FX-compatible core)

**Step 2: Run full selected verification suite**

Run:

```bash
bash tests/host/test_chain_v2_midi_fx_host_api.sh
bash tests/host/test_chain_mod_host_api_surface.sh
bash tests/host/test_chain_mod_runtime_state.sh
bash tests/host/test_chain_mod_base_effective_semantics.sh
bash tests/host/test_chain_mod_slot_agnostic_wiring.sh
bash tests/host/test_param_lfo_build_wiring.sh
bash tests/host/test_chain_mod_clear_restores_base.sh
bash tests/shadow/test_shadow_ui_order.sh
bash tests/shadow/test_shadow_display_order.sh
bash tests/shadow/test_shadow_param_lfo_target_picker.sh
bash tests/shadow/test_param_lfo_no_baked_target_values.sh
```

Expected: PASS for all selected scripts.

**Step 3: Optional build verification**

Run: `./scripts/build.sh`
Expected: `build/modules/midi_fx/param_lfo/dsp.so` exists and build completes.

**Step 4: Commit docs + verification artifacts**

```bash
git add docs/MODULES.md docs/API.md CLAUDE.md MANUAL.md
git commit -m "docs: document core modulation bus and param_lfo module"
```

**Step 5: Final status check**

Run:

```bash
git status --short
git log --oneline -n 12
```

Expected: clean working tree and coherent commit sequence.
