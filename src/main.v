import ui
import os
import json
import gg
import time

// ---------- Data Types ----------

@[heap]
struct App {
mut:
    window       &ui.Window = unsafe { nil }
    count        int
    active_tab   int // 0: Counter, 1: Todo, 2: Settings
    dark_mode    bool
    theme_name   string
    // accents
    accent_counter          gg.Color
    accent_counter_hover    gg.Color
    accent_counter_pressed  gg.Color
    accent_todo             gg.Color
    accent_todo_hover       gg.Color
    accent_todo_pressed     gg.Color
    accent_settings         gg.Color
    accent_settings_hover   gg.Color
    accent_settings_pressed gg.Color
    // paths
    data_path    string // where autosave/load happens
    io_path      string // ad-hoc import/export path
    // Todo state
    todos        map[int]TodoItem
    next_todo_id int
    new_todo     string
    edit_inputs  map[int]string
    // settings persistence
    settings     Settings
}

struct TodoItem {
mut:
    title string
    done  bool
}

struct PersistedTodo {
    id    int
    title string
    done  bool
}

struct Settings {
    dark_mode  bool
    theme_name string
}

struct ThemeProfile {
    name        string
    win_bg      string
    label_color string
    btn_bg      string
    btn_hover   string
    btn_pressed string
}

// ---------- UI Construction ----------

fn (mut app App) build() &ui.Window {
    return ui.window(
        width:  560
        height: 340
        title:  'V GUI Ideas'
        bg_color: gg.rgb(32, 34, 37)
        icon_path: app.icon_path()
        children: [
            ui.column(
                margin: ui.Margin{20, 20, 20, 20}
                spacing: 12
                children: [
                    ui.row(
                        spacing: 8
                        children: [
                            ui.image(path: app.icon_path(), width: 24, height: 24),
                            ui.label(text: 'V GUI Ideas', text_color: gg.white),
                        ]
                    ),
                    ui.row(
                        spacing: 8
                        children: [
                            ui.button(id: 'tab_counter', text: app.tab_title(0), on_click: app.select_counter,
                                bg_color: app.accent_counter, bg_color_hover: app.accent_counter_hover, bg_color_pressed: app.accent_counter_pressed,
                                text_color: gg.white),
                            ui.button(id: 'tab_todo', text: app.tab_title(1), on_click: app.select_todo,
                                bg_color: app.accent_todo, bg_color_hover: app.accent_todo_hover, bg_color_pressed: app.accent_todo_pressed,
                                text_color: gg.white),
                            ui.button(id: 'tab_settings', text: app.tab_title(2), on_click: app.select_settings,
                                bg_color: app.accent_settings, bg_color_hover: app.accent_settings_hover, bg_color_pressed: app.accent_settings_pressed,
                                text_color: gg.white)
                        ]
                    ),
                    ui.column(
                        id: 'tab_content'
                        children: [app.counter_view()]
                    ),
                ]
            )
        ]
    )
}

// ---------- Tabs ----------

fn (app &App) tab_title(idx int) string {
    titles := ['Counter', 'Todo', 'Settings']
    prefix := if app.active_tab == idx { '▶ ' } else { '' }
    return prefix + titles[idx]
}

fn (mut app App) select_counter(b &ui.Button) { app.active_tab = 0; app.switch_tab() }
fn (mut app App) select_todo(b &ui.Button)    { app.active_tab = 1; app.switch_tab() }
fn (mut app App) select_settings(b &ui.Button){ app.active_tab = 2; app.switch_tab() }

fn (mut app App) switch_tab() {
    mut content := app.window.get_or_panic[ui.Stack]('tab_content')
    if content.children.len > 0 { content.remove(at: 0) }
    match app.active_tab {
        0 { content.add(child: app.counter_view()) }
        1 { content.add(child: app.todo_view()) }
        2 { content.add(child: app.settings_view()) }
        else { content.add(child: app.counter_view()) }
    }
    // update tab button titles
    mut bc := app.window.get_or_panic[ui.Button]('tab_counter')
    mut bt := app.window.get_or_panic[ui.Button]('tab_todo')
    mut bs := app.window.get_or_panic[ui.Button]('tab_settings')
    bc.text = app.tab_title(0)
    bt.text = app.tab_title(1)
    bs.text = app.tab_title(2)
    // highlight active tab
    if app.active_tab == 0 {
        bc.update_style_params(ui.ButtonStyleParams{ bg_color: app.accent_counter_hover })
        bt.update_style_params(ui.ButtonStyleParams{ bg_color: app.accent_todo })
        bs.update_style_params(ui.ButtonStyleParams{ bg_color: app.accent_settings })
    } else if app.active_tab == 1 {
        bc.update_style_params(ui.ButtonStyleParams{ bg_color: app.accent_counter })
        bt.update_style_params(ui.ButtonStyleParams{ bg_color: app.accent_todo_hover })
        bs.update_style_params(ui.ButtonStyleParams{ bg_color: app.accent_settings })
    } else {
        bc.update_style_params(ui.ButtonStyleParams{ bg_color: app.accent_counter })
        bt.update_style_params(ui.ButtonStyleParams{ bg_color: app.accent_todo })
        bs.update_style_params(ui.ButtonStyleParams{ bg_color: app.accent_settings_hover })
    }
    app.refresh()
}

// ---------- Counter Tab ----------

fn (mut app App) counter_view() ui.Widget {
    return ui.column(
        spacing: 10
        children: [
            ui.label(text: 'A simple counter:', text_color: gg.white),
            ui.button(id: 'inc_btn', text: 'Increment (count: ${app.count})', on_click: app.on_increment,
                bg_color: app.accent_counter, bg_color_hover: app.accent_counter_hover, bg_color_pressed: app.accent_counter_pressed,
                text_color: gg.white),
            ui.slider(width: 300, height: 20, min: 0, max: 100, val: f32(app.count), on_value_changed: app.on_slider_change),
            ui.progressbar(id: 'counter_pb', width: 300, min: 0, max: 100, val: app.count,
                color: app.accent_counter, bg_color: gg.rgb(60, 63, 68))
        ]
    )
}

fn (mut app App) on_increment(btn &ui.Button) {
    app.count++
    mut pb := app.window.get_or_panic[ui.ProgressBar]('counter_pb')
    pb.val = app.count
    mut b := app.window.get_or_panic[ui.Button]('inc_btn')
    b.text = 'Increment (count: ${app.count})'
    app.refresh()
}

fn (mut app App) on_slider_change(sl &ui.Slider) {
    app.count = int(sl.val)
    mut pb := app.window.get_or_panic[ui.ProgressBar]('counter_pb')
    pb.val = app.count
    mut b := app.window.get_or_panic[ui.Button]('inc_btn')
    b.text = 'Increment (count: ${app.count})'
    app.refresh()
}

// ---------- Todo Tab ----------

fn (mut app App) todo_view() ui.Widget {
    if app.todos.len == 0 && app.next_todo_id == 0 {
        app.todos[0] = TodoItem{ title: 'Try adding a todo', done: false }
        app.next_todo_id = 1
    }
    total := app.todos.len
    done := app.todos.values().filter(it.done).len
    return ui.column(
        spacing: 8
        children: [
            ui.row(spacing: 10, children: [
                ui.label(id: 'todo_counts', text: 'Todos: ${done}/${total} done', text_color: gg.white),
                ui.button(text: 'Clear done', on_click: app.on_todo_clear_done, bg_color: app.accent_todo, text_color: gg.white),
                ui.button(text: 'Mark all', on_click: app.on_todo_mark_all, bg_color: app.accent_todo, text_color: gg.white),
            ]),
            ui.column(id: 'todo_list', scrollview: true, spacing: 4, children: app.todo_entries()),
            ui.row(widths: [ui.stretch, ui.compact], spacing: 6, children: [
                ui.textbox(id: 'todo_input', text: &app.new_todo, placeholder: 'New todo...', on_enter: app.on_todo_enter,
                    bg_color: gg.rgb(44, 47, 51), text_color: gg.white),
                ui.button(text: 'Add', on_click: app.on_add_todo, bg_color: app.accent_todo, text_color: gg.white)
            ])
        ]
    )
}

fn (mut app App) todo_entries() []ui.Widget {
    mut items := []ui.Widget{}
    for id, item in app.todos {
        if id !in app.edit_inputs { app.edit_inputs[id] = item.title }
        items << app.todo_row(id, item)
    }
    return items
}

fn (mut app App) todo_row(id int, item TodoItem) &ui.Stack {
    if id !in app.edit_inputs { app.edit_inputs[id] = item.title }
    return ui.row(
        id: 'todo_row_${id}'
        widths: [ui.compact, ui.stretch, ui.compact, ui.compact]
        spacing: 6
        children: [
            ui.checkbox(id: 'todo_cb_${id}', checked: item.done, on_click: app.on_todo_toggle),
            ui.label(id: 'todo_lab_${id}', text: item.title, text_color: gg.white),
            ui.button(id: 'todo_edit_${id}', text: 'E', on_click: app.on_todo_edit, bg_color: app.accent_todo, text_color: gg.white),
            ui.button(id: 'todo_del_${id}', text: '×', on_click: app.on_todo_delete, bg_color: gg.rgb(160, 80, 80), text_color: gg.white),
        ]
    )
}

fn (mut app App) on_todo_toggle(cb &ui.CheckBox) {
    id := cb.id.split('_').last().int()
    if mut item := app.todos[id] {
        item.done = cb.checked
        app.todos[id] = item
        app.save_todos()
        app.update_todo_counts()
    }
}

fn (mut app App) on_todo_delete(mut btn ui.Button) {
    id := btn.id.split('_').last().int()
    app.todos.delete(id)
    mut list := app.window.get_or_panic[ui.Stack]('todo_list')
    idx := list.child_index_by_id('todo_row_${id}')
    if idx >= 0 { list.remove(at: idx) }
    app.save_todos()
}

fn (mut app App) on_add_todo(_ &ui.Button) {
    title := app.new_todo.trim_space()
    if title == '' { return }
    id := app.next_todo_id
    app.next_todo_id++
    app.todos[id] = TodoItem{ title: title, done: false }
    app.new_todo = ''
    mut list := app.window.get_or_panic[ui.Stack]('todo_list')
    list.add(child: app.todo_row(id, app.todos[id]))
    app.save_todos()
    app.update_todo_counts()
}

fn (mut app App) on_todo_enter(_ &ui.TextBox) { app.on_add_todo(unsafe { nil }) }

fn (mut app App) on_todo_clear_done(_ &ui.Button) {
    mut to_remove := []int{}
    for id, item in app.todos { if item.done { to_remove << id } }
    for id in to_remove { app.todos.delete(id) }
    app.save_todos()
    app.update_todo_counts()
}

fn (mut app App) on_todo_mark_all(_ &ui.Button) {
    mut any := false
    for id, mut item in app.todos {
        if !item.done { item.done = true; any = true; app.todos[id] = item }
    }
    if any { app.save_todos(); app.update_todo_counts() }
}

fn (app &App) todo_counts_text() string {
    total := app.todos.len
    done := app.todos.values().filter(it.done).len
    return 'Todos: ${done}/${total} done'
}

fn (mut app App) update_todo_counts() {
    if app.active_tab == 1 {
        mut lab := app.window.get_or_panic[ui.Label]('todo_counts')
        lab.text = app.todo_counts_text()
    }
}

// ---------- Settings Tab ----------

fn (mut app App) settings_view() ui.Widget {
    mode := if app.dark_mode { 'Dark' } else { 'Light' }
    default_path := app.default_todos_path()
    return ui.column(
        spacing: 8
        children: [
            ui.label(text: 'Settings', text_color: gg.white),
            ui.button(text: 'Toggle theme (current: ${mode})', on_click: app.on_toggle_theme, bg_color: app.accent_settings, text_color: gg.white),
            ui.label(text: 'Theme name:', text_color: gg.white),
            ui.textbox(id: 'theme_name_tb', text: &app.theme_name, placeholder: 'dark', bg_color: gg.rgb(44, 47, 51), text_color: gg.white),
            ui.button(text: 'Apply Theme Profile', on_click: app.on_apply_theme_profile, bg_color: app.accent_settings, text_color: gg.white),
            ui.label(text: 'Data file path:', text_color: gg.white),
            ui.textbox(id: 'data_path_tb', text: &app.data_path, placeholder: default_path, bg_color: gg.rgb(44, 47, 51), text_color: gg.white),
        ]
    )
}

// ---------- Theme Management ----------

fn (app &App) themes_dir() string {
    return os.join_path(os.home_dir(), 'v-gui-ideas', 'themes')
}

fn (mut app App) load_theme_profile(name string) ?ThemeProfile {
    path := os.join_path(app.themes_dir(), '${name}.json')
    if !os.exists(path) { return error('Theme not found: ${path}') }
    data := os.read_file(path)?
    return json.decode(ThemeProfile, data)
}

fn (mut app App) on_apply_theme_profile(_ &ui.Button) {
    if profile := app.load_theme_profile(app.theme_name) {
        app.apply_theme_profile(profile)
        app.window.set_title('Applied theme: ${profile.name}')
    } else {
        app.window.set_title('Theme not found: ${app.theme_name}')
    }
}

fn (mut app App) apply_theme_profile(profile ThemeProfile) {
    app.window.bg_color = gg.hex(profile.win_bg)
    app.window.load_style()
}

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
        app.window.bg_color = gg.rgb(220, 220, 220)
    }
    app.window.load_style()
}

// ---------- Paths ----------

fn (app &App) icon_path() string {
    return os.join_path(os.home_dir(), 'v-gui-ideas', 'icon.png')
}

fn (app &App) default_todos_path() string {
    return os.join_path(os.home_dir(), 'v-gui-ideas', 'todos.json')
}

fn (app &App) todos_path() string {
    if app.data_path.trim_space() != '' { return app.data_path.trim_space() }
    return app.default_todos_path()
}

// ---------- File I/O ----------

fn (mut app App) load_todos() {
    path := app.todos_path()
    if !os.exists(path) { return }
    s := os.read_file(path) or { return }
    data := json.decode([]PersistedTodo, s) or { return }
    for item in data {
        app.todos[item.id] = TodoItem{ title: item.title, done: item.done }
        if item.id >= app.next_todo_id { app.next_todo_id = item.id + 1 }
    }
}

fn (app &App) save_todos() {
    mut arr := []PersistedTodo{}
    for id, item in app.todos { arr << PersistedTodo{ id: id, title: item.title, done: item.done } }
    s := json.encode(arr)
    path := app.todos_path()
    dir := os.dir(path)
    if !os.exists(dir) { os.mkdir_all(dir) or {} }
    os.write_file(path, s) or {}
}

// ---------- Settings Persistence ----------

fn (mut app App) load_settings() {
    path := os.join_path(os.home_dir(), 'v-gui-ideas', 'settings.json')
    if !os.exists(path) { return }
    s := os.read_file(path) or { return }
    data := json.decode(Settings, s) or { return }
    app.settings = data
    app.dark_mode = data.dark_mode
    app.theme_name = data.theme_name
}

fn (app &App) save_settings() {
    path := os.join_path(os.home_dir(), 'v-gui-ideas', 'settings.json')
    dir := os.dir(path)
    if !os.exists(dir) { os.mkdir_all(dir) or {} }
    s := json.encode(app.settings)
    os.write_file(path, s) or {}
}

// ---------- Autosave Background ----------

fn autosave_loop(mut app App) {
    for {
        app.save_todos()
        time.sleep(1 * time.minute)
    }
}

// ---------- App Lifecycle ----------

fn (mut app App) refresh() {
    app.window.set_title('V GUI Ideas — Tab: ${app.active_tab}, Count: ${app.count}')
}

// ---------- Main ----------

fn main() {
    mut app := &App{
        accent_counter:          gg.rgb(60, 120, 200)
        accent_counter_hover:    gg.rgb(80, 140, 220)
        accent_counter_pressed:  gg.rgb(45, 100, 170)
        accent_todo:             gg.rgb(60, 200, 100)
        accent_todo_hover:       gg.rgb(80, 220, 120)
        accent_todo_pressed:     gg.rgb(45, 170, 85)
        accent_settings:         gg.rgb(200, 120, 60)
        accent_settings_hover:   gg.rgb(220, 140, 80)
        accent_settings_pressed: gg.rgb(170, 100, 45)
        data_path: ''
        io_path: ''
        todos: map[int]TodoItem{}
        edit_inputs: map[int]string{}
        theme_name: 'dark'
    }
    app.load_settings()
    app.load_todos()
    app.apply_theme()
    app.window = app.build()
    go autosave_loop(mut app)
    ui.run(app.window)
}
