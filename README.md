# V GUI Ideas

A starter V project to explore simple GUI ideas using V. Includes a minimal window and a list of beginner-friendly features to try.

## Prerequisites
- Install V: https://vlang.io

## Run
```bash
v run src/main.v
```

## Idea board
- Counter button with toast/modal
- Simple todo list (in-memory)
- Color picker that changes window background
- Stopwatch / timer with start/stop/reset
- File open dialog that previews text files
- Basic drawing canvas (lines/circles)
- Theme switcher (light/dark)
✅ Dark/Light Toggle

Button to toggle UI theme.

Ctrl+T shortcut for keyboard toggle.

Saves state to settings.json.

✅ Theme Profiles

Load .json theme files from themes/ folder.

Hover preview changes window background without applying permanently.

Click to apply theme.

Ctrl+1..9 to apply theme by index.

Saves selected theme in settings.json.

✅ Todo List

Add Todos via input + Add Todo button or Enter.

Edit Todos inline via E button or Enter on selected row.

Delete Todos via × button, Del, or Backspace.

Delete all Todos via Delete All Todos button.

Todo list persists in todos.json.

✅ Keyboard Navigation

Ctrl+Up / Ctrl+Down → select Todo row.

Selection is visually highlighted in blue.

Hovering rows shows dark gray highlight for preview.

✅ Hover Effects

Todo rows highlight on hover (dark gray).

Theme buttons highlight on hover and preview theme.

Hover leaves reset to current theme or selected Todo highlight.

✅ Persistence

Todos and settings persist between sessions.

Theme and dark/light mode are saved automatically.


✅ Changelog / Fixes from your original code

Removed obsolete ui.input, replaced with ui.textbox

Removed user_data usage — closures capture app directly

Replaced row.on_hover / on_hover_leave → hoverable + on_mouse_enter / on_mouse_leave

Removed ui.Window.get_widget calls — stored widgets (todo_column, new_todo_box) in App

gg.transparent replaced with gg.rgba(0,0,0,0)

ui.Stack / ui.Column misuse fixed — returns proper ui.Widget array

max replaced with max_int helper

gg.hex(u32) casting fixed

Keyboard shortcuts omitted (can be added later via win.set_on_key_down)

Theme hover preview works without user_data

Todo input supports adding new and editing existing items

Everything compiles with current V (v0.4x stable)

✅ TL;DR

ui.input → ui.textbox

ui.Stack.user_data / hover → hoverable + on_mouse_enter/on_mouse_leave

ui.Window.get_widget() → keep a reference in App

gg.transparent → gg.rgba(0,0,0,0)

Remove old keyboard shortcut helpers

✅ New Features Added:

Arrow navigation through todos (Up/Down).

Enter to edit the selected todo.

Selected row always highlighted.

Hover effects remain functional

✅ New Features in This Version:

Inline editing: Click "Edit" or press Enter to replace a todo row with a textbox directly.

Keyboard-friendly: Arrow keys navigate, Enter edits, shortcuts disable while editing.

Clean hover + selection colors remain intact.

Works fully in V stable without hacks or deprecated functions.

✅ Features Included:

Full inline editing with focus and select-all.

Escape key cancels editing.

Hover highlight on rows.

Edit/Delete buttons fully functional.

Keyboard shortcuts (up/down to select, Enter to edit).

Load/save JSON for todos.

🔹 Features

Inline editing with focus and select-all.

Escape key cancels editing.

Hover highlights for rows.

Edit/Delete buttons functional.

Keyboard navigation: arrow keys + Enter to edit.

Add/Save buttons for todos.

JSON-based persistence.

✅ Features in this version

Inline editing with Enter to save, Escape to cancel.

Hover effect on each row.

Add/Delete/Save buttons.

Keyboard navigation (up/down + Enter).

Theme buttons with live switching.

Persistent JSON storage (todos.json).
✅ New Features in this version

Dynamic themes — fully editable inside the app.

Live theme preview — colors update instantly.

Inline editing + keyboard navigation intact.

JSON storage for todos persists as before.
