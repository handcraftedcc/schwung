# Input Modes

Input Modes let Schwung change how Move's physical pads feed the selected track before Move's firmware receives the event.

The first implementation is intentionally small and safe. It ships three core input modules plus the built-in Native option:

- **Native**: Move receives pad notes normally.
- **32 Drum Pads**: the 32 pads are remapped to consecutive drum notes from MIDI note 36 upward. The `root_octave` parameter offsets that base in octaves.
- **Chromatic**: the 32 pads are remapped to a chromatic range from a configurable `root` and `octave`, then injected back into Move as external cable-2 MIDI on the selected track's channel. The original pad note is blocked so Move only hears the remapped note.
- **Chords**: each pad emits a three-note scale chord. The `root`, `scale`, `index_2`, and `index_3` parameters define the chord tones; defaults are root, third, and fifth.

LED behavior is still native in this pass. The shared state includes per-track LED mode and track color cache fields so LED-driving modules can be added later without changing the persistence format.

The shim only applies input overrides when Move's pad LED grid looks like a playable Note layout. It watches Move's own pad LED MIDI, ignores pads that are currently held, and classifies the grid only after native navigation gestures that repaint the pads: track buttons, Menu, and Shift + Step 1. Normal pad playing does not continuously reclassify the grid.

- Note layouts pass when the grid is mostly two colors, with optional off pads for chromatic layouts.
- Drum layouts pass when the left half is a consistent drum-pad color and the right half is off or note-like.
- Track and Set layouts fail because they are row-uniform track colors or many independent set colors.

Unknown layouts fail closed, so Session view, Set Overview, and set selection pass pad events through unchanged.

## On-Device Shortcut

Open the Input Mode menu with:

```text
Shift + Volume Touch + Step 9
```

In the menu:

- Press a track button to choose the track you are editing.
- If the track is Native, the menu opens to the input module selector.
- Selecting a module opens that module's detail page.
- Every input module detail page includes a **Swap Module** row that returns to the selector.
- Module detail pages are generated from the module's `chain_params` in `module.json`.
- Click a parameter to enter edit mode, use the jog wheel or a hardware knob to adjust it, then click again to confirm. This matches the normal Shadow UI parameter workflow.
- Press Back to return to the Slots menu.

Step 9 lights while Shift and Volume Touch are held, matching the existing Step 2 and Step 13 shortcut hints.

When a non-Native melodic layout is active, the native - and + buttons are intercepted and sent to the active input module's button handler. The bundled melodic modules map those actions to their `octave` parameter and return the updated parameter value through the input module API. Held notes are released before the octave changes to avoid stuck notes. Drum layouts keep those buttons native for now because their exposed control is `root_octave`.

## Persistence

Input mode settings are saved per set in:

```text
/data/UserData/schwung/set_state/<set-uuid>/input_modes.json
```

The default fallback set uses:

```text
/data/UserData/schwung/slot_state/input_modes.json
```

The file is human-readable JSON:

```json
{
  "input_modes": {
    "tracks": {
      "1": {
        "module": "native",
        "params": {
          "layout": "native"
        },
        "mode": "native",
        "led_mode": "pass_through"
      },
      "2": {
        "module": "chromatic",
        "params": {
          "root": 0,
          "scale": "major",
          "octave": 0
        },
        "mode": "true_chromatic_poc",
        "led_mode": "pass_through"
      }
    }
  }
}
```

Missing tracks default to Native. Invalid mode names also fall back to Native.

## Module Metadata

Input modes are discovered from installed modules with:

```json
{
  "component_type": "input_mode",
  "dsp": "dsp.so",
  "input_mode": {
    "engine": "native_dsp",
    "mode": "true_chromatic_poc"
  }
}
```

The built-in input modules live under:

```text
src/modules/input_modes/
```

Their `chain_params` entries define the UI used by the Shadow UI. Their real-time mapping lives in each module's bundled `dsp.so`, loaded from `/data/UserData/schwung/modules/input_modes/<module-id>/dsp.so`.

For native input modules, set `dsp` to the shared object filename and use `input_mode.engine: "native_dsp"`. The shared object must export `schwung_input_module_init_v1()` from `src/host/input_mode_api_v1.h`. The API receives raw MIDI/button packets and returns replacement MIDI packets, optional light packets, and optional parameter updates.

For compatibility with earlier state files, `input_mode.mode` can still be one of the supported layout values:

- `native`
- `drum32`
- `true_chromatic_poc`
- `chord_pads`

If a module has a `layout`, `mode`, `host_mode`, or `input_mode` parameter, that saved parameter value takes priority over `input_mode.mode`. This preserves compatibility with early test-state files while one-layout modules activate their MIDI transform as soon as they are selected.

For compatibility with simple module ids, `true-chromatic`, `32-drum-pads`, `drum-pads`, and `chord-pads` are accepted aliases for the same built-in layouts.

The current set's musical context is also mirrored into shared memory for future input modules:

- `rootNote`
- `scale`
- `melodicLayout`

Shadow UI modules can read it with `shadow_get_set_musical_context()`. The values are refreshed from the active set's `Song.abl` file when set tracking detects a loaded set.

## Developer Notes

The host-side core lives in `src/host/input_mode.c` and is deliberately independent of the shim. It loads input module DSP files, forwards module params, tracks held pads for safe note-offs, and carries a separate light-packet list for modules that want to repaint pads later. Unit tests compile the bundled input modules as shared objects and cover module loading, pad mapping, pass-through behavior, and panic notes emitted when switching a track back to Native while notes are held.

The shim owns the real-time wiring:

- `src/schwung_shim.c` watches the selected track and intercepts cable-0 pad notes.
- Remapped notes are queued through `shadow_chain_midi_inject()` as cable-2 packets.
- `shadow_midi_force_defer(2)` prevents same-frame cable-0/cable-2 injection races.
- `src/shadow/shadow_ui.js` loads and saves per-set input mode state.

Any future mode should follow the same rule as the current Chromatic mode: if Schwung transforms a physical pad event, block the original pad event and emit all required note-offs when the mode changes.
