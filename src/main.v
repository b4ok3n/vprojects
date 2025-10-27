import ui
import os
import json
import gg
import strconv

// ---------- Data Structures ----------
struct ThemeProfile {
	name   string
	win_bg string
}

struct Settings {
mut:
	dark_mode  bool
	theme_name string
}

struct TodoItem {
	text string
}

@[heap]
struct App {
mut:
	window         &ui.Window = unsafe { nil }
	settings       Settings
	dark_mode      bool
	accent_todo    gg.Color
	todos          []TodoItem
	themes         []ThemeProfile
	selected_todo  int
}

// ---------- Entry ----------
fn main() {
	mut app := &App{
		settings: load_settings()
		accent_todo: gg.rgb(80, 150, 240)
	}
	app.load_themes()
	app.load_todos()
	app.dark_mode = app.settings.dark_mode
	app.window = app.build()
	app.try_apply_saved_theme()
	app.register_shortcuts()
	ui.run(app.window)
}

// ---------- UI Build ----------
fn (mut app App) build() &ui.Window {
	return ui.window(
		width: 600
		height: 550
		title: 'V GUI Ideas'
		bg_color: if app.dark_mode { gg.rgb(32, 34, 37) } else { gg.rgb(245, 245, 245) }
		children: [
			ui.column(
				margin: ui.Margin{20, 20, 20, 20}
				spacing: 12
				children: [
					ui.label(text: 'V GUI Ideas', text_color: gg.white),
					ui.button(text: 'Toggle Dark/Light', on_click: app.on_toggle_theme),
					ui.label(text: 'Theme Profiles:', text_color: gg.white),
					ui.column(children: app.theme_buttons()),

					// ---------- New Todo Input ----------
					ui.row(
						spacing: 8
						children: [
							ui.input(
								id: 'new_todo_input'
								placeholder: 'Type new todo here...'
								on_text_enter: app.on_add_todo_enter
							),
							ui.button(
								text: 'Add Todo'
								on_click: app.on_add_todo_click
							)
						]
					),

					ui.button(text: 'Delete All Todos', on_click: app.on_delete_all_todos),

					ui.label(text: 'Todo List:', text_color: gg.white),
					ui.column(id: 'todo_list_column', children: app.todo_rows()),
				]
			)
		]
	)
}

// ---------- Todo ----------
fn (mut app App) todo_rows() []ui.Widget {
	mut rows := []ui.Widget{}
	for i, item in app.todos {
		rows << app.todo_row(i, item)
	}
	return rows
}

fn (mut app App) todo_row(id int, item TodoItem) ui.Widget {
	is_selected := id == app.selected_todo
	bg := if is_selected { gg.rgb(50, 50, 120) } else { gg.transparent }

	mut row := ui.row(
		spacing: 8
		bg_color: bg
		children: [
			ui.label(text: item.text, text_color: gg.white),
			ui.button(text: 'E', on_click: app.on_todo_edit, bg_color: app.accent_todo, text_color: gg.white),
			ui.button(text: '×', on_click: app.on_todo_delete, bg_color: gg.rgb(160, 80, 80), text_color: gg.white),
		]
	)

	// ---------- Hover Preview ----------
	row.on_hover(fn (mut r ui.Row) {
		mut app := &App(r.get_user_data() as &App)
		r.bg_color = gg.rgb(80, 80, 80)
	})
	row.on_hover_leave(fn (mut r ui.Row) {
		mut app := &App(r.get_user_data() as &App)
		if id == app.selected_todo {
			r.bg_color = gg.rgb(50, 50, 120)
		} else {
			r.bg_color = gg.transparent
		}
	})

	row.user_data = app
	return row
}

// ---------- Todo Handlers ----------
fn (mut app App) on_todo_edit(btn &ui.Button) {
	todo_index := app.get_todo_index_from_button(btn) or { return }
	todo_item := app.todos[todo_index]
	todo_column := app.window.get_widget('todo_list_column') or { return }
	row := todo_column.children[todo_index] or { return }

	idx := todo_index
	new_input := ui.input(
		text: todo_item.text
		on_text_enter: fn (input &ui.Input) {
			mut app := &App(input.get_user_data() as &App)
			app.todos[idx].text = input.get_text()
			app.save_todos()
			todo_column := app.window.get_widget('todo_list_column') or { return }
			todo_column.set_children(app.todo_rows())
		}
		user_data: app
	)
	row.set_children([new_input])
}

fn (mut app App) on_todo_delete(btn &ui.Button) {
	idx := app.get_todo_index_from_button(btn) or { return }
	app.todos.delete(idx)
	app.save_todos()
	todo_column := app.window.get_widget('todo_list_column') or { return }
	todo_column.set_children(app.todo_rows())
	if app.selected_todo >= app.todos.len {
		app.selected_todo = max(0, app.todos.len - 1)
	}
}

fn (mut app App) on_delete_all_todos(_ &ui.Button) {
	app.todos.clear()
	app.save_todos()
	todo_column := app.window.get_widget('todo_list_column') or { return }
	todo_column.set_children(app.todo_rows())
	app.selected_todo = 0
}

fn (mut app App) on_add_todo_click(_ &ui.Button) {
	app.add_todo_from_input()
}

fn (mut app App) on_add_todo_enter(input &ui.Input) {
	app.add_todo_from_input()
}

fn (mut app App) add_todo_from_input() {
	input := app.window.get_widget('new_todo_input') or { return }
	text := input.get_text().trim_space()
	if text.len == 0 { return }
	app.todos << TodoItem{text}
	input.set_text('')
	todo_column := app.window.get_widget('todo_list_column') or { return }
	todo_column.set_children(app.todo_rows())
	app.save_todos()
}

// ---------- Todo Utilities ----------
fn (app &App) get_todo_index_from_button(btn &ui.Button) ?int {
	todo_column := app.window.get_widget('todo_list_column') or { return none }
	for i, row in todo_column.children {
		if row.children.contains(btn) {
			return i
		}
	}
	return none
}

// ---------- Todo Persistence ----------
fn (mut app App) save_todos() {
	data := json.encode(app.todos)
	os.write_file('todos.json', data) or { println('Failed to save todos') }
}

fn (mut app App) load_todos() {
	if !os.exists('todos.json') { return }
	data := os.read_file('todos.json') or { return }
	app.todos = json.decode([]TodoItem, data) or { []TodoItem{} }
}

// ---------- Dark/Light ----------
fn (mut app App) on_toggle_theme(_ &ui.Button) {
	app.dark_mode = !app.dark_mode
	app.settings.dark_mode = app.dark_mode
	app.save_settings()
	app.apply_theme()
}

fn (mut app App) apply_theme() {
	if app.dark_mode {
		app.window.bg_color = gg.rgb(32, 34, 37)
	} else {
		app.window.bg_color = gg.rgb(245, 245, 245)
	}
	app.window.load_style()
}

// ---------- Theme ----------
fn (mut app App) load_themes() {
	if !os.exists('themes') {
		os.mkdir('themes') or { println('Failed to create themes folder') }
		return
	}
	files := os.ls('themes') or { return }
	for file in files {
		if file.ends_with('.json') {
			data := os.read_file(os.join_path('themes', file)) or { continue }
			profile := json.decode(ThemeProfile, data) or { continue }
			app.themes << profile
		}
	}
}

fn (mut app App) theme_buttons() []ui.Widget {
	mut buttons := []ui.Widget{}
	for theme in app.themes {
		bg := parse_hex_color(theme.win_bg)
		text_color := if app.dark_mode { gg.white } else { gg.black }
		buttons << ui.button(
			text: theme.name
			bg_color: bg
			text_color: text_color
			user_data: app
			on_click: fn (mut btn ui.Button) {
				mut app := &App(btn.get_user_data() as &App)
				app.apply_theme_by_name(btn.text)
			}
			on_hover: fn (mut btn ui.Button) {
				mut app := &App(btn.get_user_data() as &App)
				for t in app.themes {
					if t.name == btn.text {
						app.window.bg_color = parse_hex_color(t.win_bg)
						app.window.load_style()
						return
					}
				}
			}
			on_hover_leave: fn (mut btn ui.Button) {
				mut app := &App(btn.get_user_data() as &App)
				app.try_apply_saved_theme()
			}
		)
	}
	return buttons
}

fn (mut app App) apply_theme_by_name(name string) {
	for t in app.themes {
		if t.name == name {
			app.apply_theme_profile(t)
			app.settings.theme_name = name
			app.save_settings()
			app.window.set_title('Theme applied: $name')
			return
		}
	}
	println('Theme not found: $name')
}

fn (mut app App) apply_theme_profile(profile ThemeProfile) {
	app.window.bg_color = parse_hex_color(profile.win_bg)
	app.window.load_style()
}

fn (mut app App) try_apply_saved_theme() {
	if app.settings.theme_name.len == 0 { return }
	app.apply_theme_by_name(app.settings.theme_name)
}

// ---------- Settings ----------
fn (mut app App) save_settings() {
	data := json.encode(app.settings)
	os.write_file('settings.json', data) or { println('Failed to save settings') }
}

fn load_settings() Settings {
	if !os.exists('settings.json') {
		return Settings{dark_mode: true, theme_name: 'default'}
	}
	data := os.read_file('settings.json') or { return Settings{dark_mode: true, theme_name: 'default'} }
	return json.decode(Settings, data) or { return Settings{dark_mode: true, theme_name: 'default'} }
}

// ---------- Utils ----------
fn parse_hex_color(s string) gg.Color {
	mut t := s.trim_space()
	if t.starts_with('#') {
		t = t[1..]
	}
	val := u32(strconv.parse_uint(t, 16, 32) or { return gg.black })
	return gg.hex(val)
}

// ---------- Keyboard Shortcuts ----------
fn (mut app App) register_shortcuts() {
	ui.on_key_down(fn (mut evt ui.KeyEvent) {
		mut app := &App(evt.user_data as &App)
		mut todo_column := app.window.get_widget('todo_list_column') or { return }

		match evt.key {
			.t { if evt.ctrl { app.on_toggle_theme(ui.Button{}) } }
			.up { 
				if evt.ctrl { 
					app.selected_todo = max(0, app.selected_todo - 1)
					todo_column.set_children(app.todo_rows())
				} 
			}
			.down { 
				if evt.ctrl { 
					app.selected_todo = min(app.todos.len - 1, app.selected_todo + 1)
					todo_column.set_children(app.todo_rows())
				} 
			}
			.enter {
				if app.todos.len == 0 { return }
				row := todo_column.children[app.selected_todo] or { return }
				edit_btn := row.children[1] or { return }
				app.on_todo_edit(edit_btn as &ui.Button)
			}
			.del, .backspace {
				if app.todos.len == 0 { return }
				row := todo_column.children[app.selected_todo] or { return }
				del_btn := row.children[2] or { return }
				app.on_todo_delete(del_btn as &ui.Button)
				if app.selected_todo >= app.todos.len {
					app.selected_todo = max(0, app.todos.len - 1)
				}
			}
			'1'...'9' {  // <-- Fixed inclusive range
				idx := int(evt.key - `1`)
				if idx < app.themes.len { app.apply_theme_by_name(app.themes[idx].name) }
			}
			else {}
		}
	}, app)
}
