# Temporary LFO Modulation (Core) Design

## Goal
Add a non-destructive runtime modulation layer to the core Signal Chain engine so an LFO-style module can modulate parameters temporarily without overwriting stored base parameter values.

## Why This Design
Current parameter control writes directly through normal `set_param` flows. That is correct for direct edits, but not for modulation. Continuous writes from an LFO destroy base state semantics and make save/load behavior fragile.

This design introduces a core runtime modulation bus in the chain engine so:
- base values remain authoritative for persistence and manual editing
- modulation is temporary and recomputed at runtime
- modulation sources are slot-agnostic from the core side (MIDI FX and Audio FX compatible)

## Scope (v1)
- Same-chain modulation only (within a single slot's chain instance)
- Numeric targets only (`float`, `int`, `enum` excluded for v1 modulation writes)
- One active source per target for first pass (data model leaves room for multiple later)
- Control-rate updates (no sample-accurate modulation)
- Core is slot-agnostic for source component type
- First UI module can be MIDI FX only, but core must support future Audio FX source modules

## Non-Goals (v1)
- Cross-slot modulation
- Multi-target macros
- Modulation recording/automation lanes
- Committing effective (modulated) values back to base values
- Full modulation matrix UI

## Architecture

### 1. Core Modulation Bus in Chain Host
Implement modulation state and routing in:
- `src/modules/chain/dsp/chain_host.c`

This layer owns:
- target registration and lookup
- base value cache for modulated targets
- runtime effective value computation (`effective = clamp(base + contribution)`)
- dispatch of effective values to target sub-plugins

### 2. Host API Extension for Sub-Plugins
Extend host API surface in:
- `src/host/plugin_api_v1.h`

Add optional modulation callback fields at the end of `host_api_v1_t` so source modules can publish modulation samples without ABI breakage for older modules.

Design intent:
- source module provides `target` + `param` + normalized signal/offset
- core modulation bus resolves metadata, clamps, and applies effective value

Because Audio FX v2 and MIDI FX v1 modules both receive `host_api_v1_t`, this makes the core source-slot agnostic.

### 3. Base vs Effective Semantics
For each modulated target parameter, core tracks:
- `base_value`: last explicit user/patch value
- `mod_value` (or contribution)
- `effective_value`: computed runtime value sent to plugin

Rules:
- explicit `set_param` updates base value
- modulation never rewrites base value
- modulation update recomputes effective and pushes to plugin
- when modulation disables/unbinds, target returns to base immediately

### 4. Save/Load Semantics
Patch and slot save/load continue to persist base/module state (as they do today):
- target plugin `state` remains the source of truth for base parameter persistence
- LFO module stores mapping/rate/depth/shape in its own state
- runtime modulation contributions are not serialized as target base values

## Core Data Model (Conceptual)
Inside `chain_instance_t`, add runtime structs similar to:
- modulation source state (source id/component)
- modulation bindings (`source -> target:param`)
- target runtime cache (base/effective/active metadata)

Keep this internal to chain host for v1; no new shared-memory schema required.

## Data Flow

### A. Manual/Explicit Parameter Change
1. UI or patch restore calls `v2_set_param("target:param", value)`
2. chain host updates base cache for that modulated target
3. chain host recomputes effective if modulation active
4. effective value is sent to sub-plugin

### B. Modulation Update from Source Module
1. source module emits modulation sample through host API callback
2. chain host resolves target metadata and current base
3. chain host computes clamped effective value
4. chain host sends effective value to target plugin

### C. Modulation Disable/Unbind
1. source disabled/unbound/removed
2. chain host clears contribution
3. chain host reapplies base value to target

## Slot-Agnostic Source Support
From core engine perspective, source component type does not matter if it can call host modulation callback:
- `midi_fx*` sources: supported
- `fx*` sources: supported by same host callback contract

For delivery sequence, we can ship first source module as MIDI FX, while keeping core API and runtime compatible with future Audio FX LFO modules.

## UI Integration Strategy (v1)
Reuse existing target-discovery logic already present in Shadow UI:
- `src/shadow/shadow_ui.js` functions used by knob mapping target picker

For first delivery, keep UI changes minimal:
- expose/select target component + parameter using existing picker patterns
- enforce v1 target filters (same chain, numeric params, exclude unsupported/self per UI rules)

## Error Handling
- Ignore modulation updates with unknown/unloaded targets
- Ignore non-numeric or missing metadata targets
- Clamp values to param min/max before set
- Emit debug logs for invalid bindings or parse failures (no crash/no hard failure)

## Performance Considerations
- Control-rate only update path
- cache metadata lookups for bound targets
- avoid expensive string scanning on every modulation tick where possible

## Test Strategy
Add focused regression tests:
- modulation callback wiring from source plugin to core bus
- base value unchanged under active modulation
- manual edit while modulated updates base and effective correctly
- unbind/disable returns to base
- save/load retains base + mapping state, no baked effective value

Use existing shell/host test style under `tests/host` and `tests/shadow`.

## Rollout Plan
1. Core modulation bus + host API extension
2. Minimal built-in LFO module (MIDI FX) using new callback
3. Shadow UI target-picker integration
4. Save/load and regression coverage
5. Optional follow-up: Audio FX LFO module implementation using same core API
