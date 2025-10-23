# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview
- Language/toolchain: V
- Purpose: Small GUI sandbox to try simple ideas (see README “Idea board”).
- Entrypoint: src/main.v
- Module metadata: v.mod (module name: v_gui_ideas)

## Commands
- Run (from README):
  - v run src/main.v
  - v run .
- Build optimized binary:
  - v -prod -o bin/v_gui_ideas src/main.v
  - v -prod -o bin/v_gui_ideas .
- Develop with auto-rebuild on change:
  - v watch run .
- Format:
  - v fmt -w .
- Static checks:
  - v vet .
- Tests (none in repo yet, but supported):
  - Run all: v test .
  - Single file: v test path/to/foo_test.v
  - Single test name: v test -run "test_name_regex" .

## Architecture and structure
- Single V module (v.mod) with source under src/.
- App struct holds UI state (window handle and simple count). Methods on App handle events.
- UI is declared with ui.window containing a column of widgets (label, button). Button onclick is bound to App.on_increment, which mutates state and updates the window title to trigger a redraw.
- Extending the app:
  - Add state to App for new features (e.g., todos, colors, timers).
  - Add new event handler methods on App and compose additional ui.* widgets in App.build().
  - Place additional feature code in new .v files under src/ within the same module; V will compile them automatically.
