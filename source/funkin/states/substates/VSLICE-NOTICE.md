# FNF V-Slice pause menu adaptation

`VSlicePauseSubState.hx` adapts the standard pause menu's entry list, dim background,
scrolling bold text, selected-entry opacity, metadata, difficulty submenu and practice
mode behavior from the official Friday Night Funkin' source:

- Upstream: <https://github.com/FunkinCrew/Funkin>
- File: `source/funkin/play/PauseSubState.hx`
- Reference revision: `b2215482c25c5e98a72ac47b4807018934480d01`
- Copyright 2020–2024 The Funkin' Crew Inc.
- License: Apache License 2.0; the upstream license notice and text are bundled in
  `assets/embeds/mobile/VSLICE-LICENSE.txt`.

The adaptation uses this mod's existing Alphabet and font assets, state lifecycle,
Psych mobile controls, chart loading and pause music. It does not copy the upstream
asset pack, mobile ads, chart registry, cutscene controls or runtime framework.
Difficulty entries are limited to charts actually present for the selected song.
