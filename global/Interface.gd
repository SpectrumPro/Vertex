# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CoreInterface extends Node
## Main script for the Spectrum Lighting Controller UI interface


## Emitted when a resolve request is required
signal resolve_requested(type: Data.Type, sub_type: int, hint: ResolveHint, classname: String, color_hint: Color)

## Emitted when a window is added
signal window_added(window: UIWindow)

## Emitted when a window is removed
signal window_removed(window: UIWindow)

## Emitted when the UI scale factor is changed
signal scale_factor_changed(scale_factor: float)

## Emitted when the save ui on quit state is changed
signal save_ui_on_quit_changed(save_ui: bool)

## Emitted before the program is exited
signal program_closing()


## Enum for ResolveHint
enum ResolveHint {
	NONE,				## Default state
	SELECT,				## Requests to select a component
	ASSIGN,				## Requests to assign into
	STORE,				## Requests to store into
	EDIT,				## Requests to edit
	RENAME,				## Requests to rename a component
	EXECUTE,			## Requests to execute a function
	STOP,				## Requests to stop a function
	DELETE				## Requests to delete a component
}

## The current resolve hint, if any
var _current_resolve_hint: ResolveHint = ResolveHint.NONE

## The current resolve mode, if any
var _current_resolve_type: Data.Type = Data.Type.NULL

## The current resolve mode, if any
var _current_resolve_subtype: int = Data.Sub.Type.NULL

## The current resolve classname
var _current_resolve_classname: String = ""

## The current resolve color
var _current_resolve_color: Color = Color.TRANSPARENT

## The resolve Promise
var _resolve_promise: Promise = Promise.new()

## Colors for each resolve hint
var _resolve_hint_colors: Dictionary[ResolveHint, Color] = {
	ResolveHint.NONE:		ThemeManager.Colors.ResolveHint.None,
	ResolveHint.SELECT:		ThemeManager.Colors.ResolveHint.Select,
	ResolveHint.ASSIGN:		ThemeManager.Colors.ResolveHint.Assign,
	ResolveHint.STORE:		ThemeManager.Colors.ResolveHint.Store,
	ResolveHint.EDIT:		ThemeManager.Colors.ResolveHint.Edit,
	ResolveHint.RENAME:		ThemeManager.Colors.ResolveHint.Rename,
	ResolveHint.EXECUTE:	ThemeManager.Colors.ResolveHint.Execute,
	ResolveHint.STOP:		ThemeManager.Colors.ResolveHint.Stop,
	ResolveHint.DELETE:		ThemeManager.Colors.ResolveHint.Delete,
}


## Stores configuration for each WindowPopup that will be instanced on each window
var _window_popup_config: Dictionary[Script, PopupConfig] = {
	UIPanelSelector:		PopupConfig.new("UIPanelSelector", ""),
	UIPanelSettings:		PopupConfig.new("UIPanelSettings", "set_panel"),
	UICommandPalette:		PopupConfig.new("UICommandPalette", ""),
	UIObjectSelector:		PopupConfig.new("UIObjectSelector", ""),
	UIPopupSettingsModule:	PopupConfig.new("UIPopupSettingsModule", "set_module"),
	UIWindowManager:		PopupConfig.new("UIWindowManager", ""),
	UIWindowID:				PopupConfig.new("UIWindowID", ""),
	UINetworkSelector:		PopupConfig.new("UINetworkSelector"),
	UISettingsManager:		PopupConfig.new("UISettingsManager", "set_manager"),
}

## All windows by UUID RefMap for UUID: Window
var _windows: RefMap = RefMap.new()

## All WindowPopup scenes per window
var _window_popups: Dictionary[Window, Control]

## The WindowPopups scene to be instanced on each window
var _window_popups_scene: PackedScene = load("res://WindowPopups.tscn")

## All active fade animations
var _active_fade_animations: Dictionary[Object, Dictionary]

## All open UIPopupDialog refernced by the source node
var _open_popup_dialogs: Dictionary[Node, UIPopupDialog]

## Contains all searchable items
var _palette_search_index: Dictionary[String, Dictionary]

## Config items for the ObjectPicker
var _object_picker_index: Dictionary[Script, ClassTreeConfig]

## The settings manager for ClientInterface
var _settings: SettingsManager = SettingsManager.new()


## Init
func _init() -> void:
	_settings.set_owner(self)
	_settings.set_inheritance_array(["Interface"])
	
	_settings.register_setting("ScaleFactor", Data.Type.FLOAT, set_scale_factor, get_scale_factor, [scale_factor_changed]).set_min_max(0.2, 2)
	_settings.register_setting("SaveUIOnQuit", Data.Type.BOOL, set_save_ui_on_quit, get_save_ui_on_quit, [save_ui_on_quit_changed])
	
	_settings.register_control("HideAllPopups", Data.Type.ACTION, hide_all_popup_panels, Callable(), [])
	_settings.register_control("AddWindow", Data.Type.ACTION, add_window, Callable(), [])
	_settings.register_control("SaveUI", Data.Type.ACTION, save_ui, Callable(), [])
	_settings.register_control("OpenWindowManager", Data.Type.ACTION, set_popup_visable.bind(UIWindowManager, self, true), Callable(), [])
	


## Ready ClientInterface
func _ready() -> void:
	Config.load_config("res://InterfaceConfig.gd")
	Config.load_user_config()
	
	_window_popup_config.merge(Config.window_popup_config)
	
	for entry: CommandPaletteEntry in Config.command_palette_default_items:
		add_command_palette_entry(entry)
	
	for script: Script in Config.object_picker_default_items:
		_object_picker_index[script] = Config.object_picker_default_items[script]
	
	var root: Window = get_tree().root
	var popups: Control = _window_popups_scene.instantiate()
	
	_register_window_popups(popups, root)
	root.set_script(UIWindow)
	root.set_window_popups.call_deferred(popups)
	root._base_panel = root.get_node("UICore")
	
	_window_popups[root] = popups
	_windows.map("main", root)
	
	set_save_ui_on_quit(Config.save_ui_on_quit)
	set_scale_factor(Config.scale_factor)
	
	(func () -> void:
		load_ui()
	).call_deferred()


## Notification
func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_WM_CLOSE_REQUEST:
		create_popup_dialog(self, "Close Main Window?")\
		.button("Cancel", false)\
		.button("Close", true, Color.RED)\
		.then(quit)


## Registers all WindowPopups into the corrisponding PopupConfig class
func _register_window_popups(p_window_popups: Control, p_window: Window) -> void:
	for window_popup: Script in _window_popup_config.keys():
		_register_popup(window_popup, p_window_popups, p_window)


## Registers a WindowPopup on the given Window
func _register_popup(p_window_popup: Script, p_window_popups: Control, p_window: Window) -> void:
	var config: PopupConfig = _window_popup_config[p_window_popup]
	var popup: UIBase = p_window_popups.get_node(config.node_name)
	var setter: Callable
	
	if config.setter:
		setter = Callable(popup, config.setter)
	
	config.nodes[p_window] = popup
	config.setter_callables[p_window] = setter
	config.active_state[p_window] = false
	popup.hide()


## Shows the given WindowPopup
func show_window_popup(p_popup_type: Script, p_source: Node, p_setter_arg: Variant) -> Promise:
	var window = p_source.get_window()
	var config: PopupConfig = _window_popup_config[p_popup_type]
	
	var popup: UIPanel = config.nodes[window]
	var promise: Promise = Promise.new()
	
	var resolve_signal: Signal = popup.get_custom_signal_or_default() if popup is UIPopup else Signal()
	var reject_signal: Signal = popup.canceled if popup is UIPopup else popup.close_request
	
	if config.active_state[window]:
		config.promises[window].reject()
		config.promises.erase(window)
	
	if p_setter_arg:
		config.setter_callables[window].call(p_setter_arg)
	
	if not resolve_signal.is_null():
		if config.resolve_connections.has(window) and resolve_signal.is_connected(config.resolve_connections[window]):
			resolve_signal.disconnect(config.resolve_connections[window])
		
		config.resolve_connections[window] = (func (...p_args: Array):
			hide_window_popup(p_popup_type, window)
			resolve_signal.disconnect(config.resolve_connections[window])
			config.promises[window].resolve(p_args)
		)
		
		resolve_signal.connect(config.resolve_connections[window])
	
	if not reject_signal.is_null():
		if config.reject_connections.has(window) and reject_signal.is_connected(config.reject_connections[window]):
			reject_signal.disconnect(config.reject_connections[window])
		
		config.reject_connections[window] = (func (...p_args: Array):
			hide_window_popup(p_popup_type, window)
			reject_signal.disconnect(config.reject_connections[window])
			config.promises[window].resolve(p_args)
		)
		
		reject_signal.connect(config.reject_connections[window])
	
	config.active_state[window] = true
	config.promises[window] = promise
	show_and_fade(popup)
	
	popup.move_to_front()
	popup.focus()
	
	promise.set_object_refernce(popup)
	return promise


## Hides and active window popup
func hide_window_popup(p_popup_type: Script, p_window: Window) -> void:
	var config: PopupConfig = _window_popup_config[p_popup_type]
	
	if not config.active_state[p_window]:
		return
	
	config.active_state[p_window] = false
	fade_and_hide(config.nodes[p_window])


## Sets the visability of a WindowPopup
func set_popup_visable(p_popup_type: Script, p_source: Node, p_visible: bool) -> UIBase:
	if p_visible:
		show_window_popup(p_popup_type, p_source, null)
	else:
		hide_window_popup(p_popup_type, p_source.get_window())
	
	return get_window_popup(p_popup_type, p_source)


## Sets the visability of a WindowPopup
func toggle_popup_visable(p_popup_type: Script, p_source: Node) -> UIBase:
	var popup: UIBase = get_window_popup(p_popup_type, p_source)
	
	if not popup:
		return null
	
	if popup.visible:
		hide_window_popup(p_popup_type, p_source.get_window())
	else:
		show_window_popup(p_popup_type, p_source, null)
	
	return popup


## Hides all popup panels
func hide_all_popup_panels() -> void:
	for popup_type: Script in _window_popup_config:
		hide_window_popup(popup_type, get_window())


## Creates and adds a blank UIPopupDialog
func create_popup_dialog(p_source: Node, p_title: String = "") -> UIPopupDialog:
	if _open_popup_dialogs.has(p_source):
		var open_dialog: UIPopupDialog = _open_popup_dialogs[p_source]
		
		open_dialog.focus()
		open_dialog.move_to_front()
		open_dialog.flash()
		
		return UIPopupDialog.new().set_promise(Promise.new().auto_reject())
	
	var window_popups: Control = _window_popups[p_source.get_window()]
	var new_dialog: UIPopupDialog = UIDB.instance_popup(UIPopupDialog)
	var promise: Promise = Promise.new()
	
	new_dialog.get_custom_signal_or_default().connect(func (...p_args): 
		promise.resolve(p_args)
		fade_and_hide(new_dialog, new_dialog.queue_free)
		_open_popup_dialogs.erase(p_source)
	)
	new_dialog.canceled.connect(func (): 
		promise.reject()
		fade_and_hide(new_dialog, new_dialog.queue_free)
		_open_popup_dialogs.erase(p_source)
	)
	
	if p_title:
		new_dialog.title(p_title)
	
	promise.set_object_refernce(new_dialog)
	window_popups.add_child(new_dialog)
	
	new_dialog.set_promise(promise)
	new_dialog.focus()
	new_dialog.hide()
	
	show_and_fade(new_dialog, new_dialog.focus)
	_open_popup_dialogs[p_source] = new_dialog
	return new_dialog


## Prompts the user with a custom panel popup
func create_panel_popup(p_source: Node, p_panel_class: Variant) -> UIPanel:
	var window_popups: Control = _window_popups[p_source.get_window()]
	var panel: UIPanel = UIDB.instance_panel(p_panel_class)
	
	if not is_instance_valid(panel):
		return null
	
	panel.close_request.connect(func ():
		fade_and_hide(panel, panel.queue_free)
	)
	
	panel.hide()
	panel.set_display_mode(UIPanel.DisplayMode.Popup)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	window_popups.add_child(panel)
	
	show_and_fade(panel)
	return panel


## Saves the UI to the ui save file
func save_ui() -> void:
	Utils.save_json_to_file(Config.ui_file_location, Config.ui_file_name, serialize())
	Config.save_user_config()


## Loads the UI from the ui save file
func load_ui() -> void:
	deserialize(Utils.load_json_from_file(Config.ui_file_location, Config.ui_file_name))


## Seralizes the interface into a Dictionary
func serialize() -> Dictionary:
	var serialize_data: Dictionary = {
		"windows": {}
	}
	
	for window_uuid: String in _windows.get_left():
		serialize_data.windows[window_uuid] = _windows.left(window_uuid).serialize()
	
	return serialize_data


## Deserializes the serialized data
func deserialize(p_serialized_data) -> void:
	var windows: Dictionary = type_convert(p_serialized_data.get("windows", {}), TYPE_DICTIONARY)
	
	for window_uuid: Variant in windows:
		if not window_uuid is String or not windows[window_uuid] is Dictionary: 
			continue
		
		var serialized_window: Dictionary = windows[window_uuid]
		
		if window_uuid == "main":
			get_window_node(self).deserialize(serialized_window)
		else:
			add_window(null, true).deserialize(serialized_window)


## Gets the WindowPopup for the window containing the p_source node
func get_window_popup(p_window_popup: Script, p_source: Node) -> UIBase:
	if not _window_popup_config.has(p_window_popup):
		return null
	
	var window: Window = p_source.get_window()
	var config: PopupConfig = _window_popup_config[p_window_popup]
	
	return config.nodes.get(window, null)


## Fades a property of an object and handles animation cleanup
func fade_property(p_object: Object, p_property: String, p_to: Variant, p_callback: Callable = Callable(), p_time: float = ThemeManager.Constants.Times.InterfaceFadeTime) -> void:
	kill_fade(p_object, p_property)
	var tween: Tween = get_tree().create_tween()
	
	tween.tween_property(p_object, p_property, p_to, p_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func ():
		if is_instance_valid(p_object):
			_active_fade_animations[p_object].erase(p_property)
		else:
			_active_fade_animations.erase(null)
		
		if p_callback.is_valid():
			p_callback.call()
	)
	
	_active_fade_animations.get_or_add(p_object, {})[p_property] = tween


## Kills a running fade
func kill_fade(p_object: Object, p_property: String) -> void:
	if _active_fade_animations.get(p_object, {}).has(p_property):
		_active_fade_animations[p_object][p_property].kill()
		_active_fade_animations[p_object].erase(p_property)


## Checks if a property is currently fading
func is_fading(p_control: Control, p_property: String) -> bool:
	return _active_fade_animations.get(p_control, {}).has(p_property)


## Shows and fades in a control
func show_and_fade(p_control: Control, p_callback: Callable = Callable(), p_time: float = ThemeManager.Constants.Times.InterfaceFadeTime) -> void:
	if p_control.visible and not is_fading(p_control, "modulate"):
		return
	
	p_control.modulate = Color.TRANSPARENT
	fade_property(p_control, "modulate", Color.WHITE, p_callback, p_time)
	p_control.show()


## Fades and hides a control
func fade_and_hide(p_control: Control, p_callback: Callable = Callable(), p_time: float = ThemeManager.Constants.Times.InterfaceFadeTime) -> void:
	if not is_instance_valid(p_control) or not p_control.visible and not is_fading(p_control, "modulate"):
		return
	
	p_control.modulate = Color.WHITE
	fade_property(p_control, "modulate", Color.TRANSPARENT, func ():
		if is_instance_valid(p_control):
			p_control.hide()
			p_control.modulate = Color.WHITE
		
		if p_callback.is_valid():
			p_callback.call()
	, p_time)


## Sets the visibility of a control node with a fade time
func set_visible_and_fade(p_control: Control, p_visible: bool, p_callback: Callable = Callable(), p_time: float = ThemeManager.Constants.Times.InterfaceFadeTime) -> void:
	if p_visible:
		show_and_fade(p_control, p_callback, p_time)
	else:
		fade_and_hide(p_control, p_callback, p_time)


## Stops any current fade and shows the given control node
func show(p_control: Control) -> void:
	kill_fade(p_control, "modulate")
	p_control.modulate = Color.WHITE
	p_control.show()


## Stops any current fade and shows the given control node
func hide(p_control: Control) -> void:
	kill_fade(p_control, "modulate")
	p_control.modulate = Color.WHITE
	p_control.hide()


## Adds a new window
func add_window(p_base_panel: Script = null, p_no_default: bool = false) -> UIWindow:
	var new_window: UIWindow = UIWindow.new()
	var uuid: String = UUID.v4()
	var popups: Control = _window_popups_scene.instantiate()
	
	_register_window_popups(popups, new_window)
	_window_popups[new_window] = popups
	_windows.map(uuid, new_window)
	
	new_window.set_initial_position(Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_KEYBOARD_FOCUS)
	new_window.set_window_popups(popups)
	new_window.set_name("New Window")
	
	add_child(new_window, true)
	new_window.set_window_title(new_window.name)
	
	if is_instance_valid(p_base_panel):
		new_window.set_base_panel.call_deferred(UIDB.instance_panel(p_base_panel))
	elif not p_no_default:
		new_window.set_base_panel.call_deferred(UIDB.instance_panel(Config.default_ui_panel))
	
	window_added.emit(new_window)
	return new_window


## Removes the given window
func remove_window(p_window: UIWindow) -> bool:
	if not _windows.has_right(p_window) or p_window.is_window_root():
		return false
	
	_windows.erase_right(p_window)
	p_window.queue_free()
	
	remove_child(p_window)
	window_removed.emit(p_window)
	
	return true


## Shows the WindowID on all the given windows. or all windows
func show_window_id(p_on_windows: Array[UIWindow] = []) -> void:
	if not p_on_windows:
		p_on_windows = get_all_windows()
	
	for window: UIWindow in p_on_windows:
		show_window_popup(UIWindowID, window, null)


## Shows the WindowID on all the given windows. or all windows
func hide_window_id(p_on_windows: Array[UIWindow] = []) -> void:
	if not p_on_windows:
		p_on_windows = get_all_windows()
	
	for window: UIWindow in p_on_windows:
		hide_window_popup(UIWindowID, window)


## Gets all windows
func get_all_windows() -> Array[UIWindow]:
	var result: Array[UIWindow] = []
	result.assign(_windows.get_right())
	
	return result


## Gets the Window node the p_source node is in
func get_window_node(p_source: Node) -> UIWindow:
	var window: Window = p_source.get_window()
	
	while not _windows.has_right(window):
		window = window.get_window()
	
	return window


## Adds an entry to the command palette
func add_command_palette_entry(p_entry: CommandPaletteEntry) -> void:
	for module: SettingsModule in p_entry.get_settings_manager().get_modules().values():
		_palette_search_index.get_or_add(p_entry.get_class_name(), {})[module.get_id()] = module


## Gets the current ResolveHint
func get_current_resolve_hint() -> ResolveHint:
	return _current_resolve_hint


## Gets the current ResolveType
func get_current_resolve_type() -> Data.Type:
	return _current_resolve_type


## Gets the current ResolveType
func get_current_resolve_subtype() -> int:
	return _current_resolve_subtype


## Gets the current resolve classname
func get_current_resolve_classname() -> String:
	return _current_resolve_classname


## Gets the current resolve color
func get_current_resolve_color() -> Color:
	return _current_resolve_color


## Gets the color for a resolve hint
func get_resolve_color(p_resolve_hint: ResolveHint) -> Color:
	return _resolve_hint_colors[p_resolve_hint]


## Enables the ResolveMode
func enter_resolve_mode(p_type: Data.Type, p_subtype: int, p_resolve_hint: ResolveHint, p_classname: String) -> Promise:
	_current_resolve_type = p_type
	_current_resolve_subtype = p_subtype
	_current_resolve_hint = p_resolve_hint
	_current_resolve_classname = p_classname
	_current_resolve_color = get_resolve_color(_current_resolve_hint)
	
	resolve_requested.emit(_current_resolve_type, _current_resolve_subtype, _current_resolve_hint, _current_resolve_classname, _current_resolve_color)
	return _resolve_promise


## Exits resolve mode
func exit_resolve_mode() -> bool:
	if _current_resolve_type == Data.Type.NULL:
		return false
	
	_current_resolve_type = Data.Type.NULL
	_current_resolve_subtype = Data.Sub.Type.NULL
	_current_resolve_hint = ResolveHint.NONE
	_current_resolve_classname = ""
	_current_resolve_color = Color.TRANSPARENT
	
	resolve_requested.emit(_current_resolve_type, _current_resolve_subtype, _current_resolve_hint, _current_resolve_classname, _current_resolve_color)
	return true


## Resolves the current request
func resolve_request(p_with: Variant) -> void:
	if _current_resolve_type == Data.Type.NULL:
		return
	
	_resolve_promise.resolve([p_with])
	exit_resolve_mode()


## Takes a screenshot of all screens
func take_screenshot() -> void:
	for window: UIWindow in _windows.get_right():
		var file_name: String = "user://" + str(Time.get_datetime_string_from_system())
		
		window.get_viewport().get_texture().get_image().save_png(file_name)
		print("Screenshot saved as: ", file_name)


## Returns the SettingsManager object for ClientInterface
func get_settings() -> SettingsManager:
	return _settings


## Quits the program
func quit() -> void:
	program_closing.emit()
	
	if get_save_ui_on_quit():
		save_ui()
	
	get_tree().quit()


## Sets the UI Scale factor
func set_scale_factor(p_scale_factor: float) -> void:
	Config.scale_factor = p_scale_factor
	
	for window: UIWindow in _windows.get_right():
		window.content_scale_factor = p_scale_factor
	
	scale_factor_changed.emit(p_scale_factor)


## Sets the save ui on quit state
func set_save_ui_on_quit(p_save_ui: bool) -> void:
	Config.save_ui_on_quit = p_save_ui
	
	save_ui_on_quit_changed.emit(p_save_ui)

 
## Gets the UI scale factor
func get_scale_factor() -> float:
	return Config.scale_factor


## Gets the save UI on quit option
func get_save_ui_on_quit() -> bool:
	return Config.save_ui_on_quit


## Stores configs
class Config:
	## True if the UI should be saved to disk before the program closes
	static var save_ui_on_quit: bool = true

	## UI Scale factor
	static var scale_factor: float = 1
	
	## File location to store the UI Save
	static var ui_file_location: String = "user://"
	
	## File name to store the UI Save
	static var ui_file_name: String = "ui.json"
	
	## The script for the default UIPanel
	static var default_ui_panel: Script = null
	
	## File location to store the UI Save
	static var user_config_file_location: String = "user://"
	
	## File name to store the UI Save
	static var user_config_file_name: String = "interface.conf"
	
	## User defined window popups
	static var window_popup_config: Dictionary
	
	## Default items in the UICommandPalette
	static var command_palette_default_items: Array
	
	## Default items in the UIObjectPicker
	static var object_picker_default_items: Dictionary
	
	## Built in start up notics
	static var startup_notices: Array = []
	
	## Array of notice ID not to show again
	static var notices_dont_show_again: Array
	
	## ConfigFile object to save / load user config
	static var _config_access: ConfigFile = ConfigFile.new()
	
	
	## Loads config from a file
	static func load_config(p_path: String) -> bool:
		var script: Variant = load(p_path)
		
		if script is not GDScript or script.get("config") is not Dictionary:
			return false
		
		var config: Dictionary = script.get("config")
		
		save_ui_on_quit = type_convert(config.get("save_ui_on_quit", save_ui_on_quit), TYPE_BOOL)
		scale_factor = type_convert(config.get("scale_factor", scale_factor), TYPE_INT)
		default_ui_panel = type_convert(config.get("default_ui_panel", default_ui_panel), TYPE_OBJECT)
		
		window_popup_config = type_convert(config.get("window_popup_config", window_popup_config), TYPE_DICTIONARY)
		command_palette_default_items = type_convert(config.get("command_palette_default_items", command_palette_default_items), TYPE_ARRAY)
		
		object_picker_default_items = type_convert(config.get("object_picker_default_items", object_picker_default_items), TYPE_DICTIONARY)
		startup_notices = type_convert(config.get("startup_notices", startup_notices), TYPE_ARRAY)
		
		return true
	
	
	## Loads the user config
	static func load_user_config() -> Error:
		var load_err: Error = _config_access.load(get_user_config_path())
		
		if load_err:
			return load_err
		
		var block_list: Array[String] = []
		block_list.assign(type_convert(_config_access.get_value("Interface", "notices_dont_show_again"), TYPE_ARRAY))
		notices_dont_show_again = block_list
		
		scale_factor = type_convert(_config_access.get_value("Interface", "scale_factor", scale_factor), TYPE_FLOAT)
		save_ui_on_quit = type_convert(_config_access.get_value("Interface", "save_ui_on_quit", save_ui_on_quit), TYPE_BOOL)
		
		save_user_config()
		return OK
	
	
	## Saves the user config to a file
	static func save_user_config() -> Error:
		_config_access.set_value("Interface", "notices_dont_show_again", notices_dont_show_again)
		
		_config_access.set_value("Interface", "scale_factor", scale_factor)
		_config_access.set_value("Interface", "save_ui_on_quit", save_ui_on_quit)
		
		return _config_access.save(get_user_config_path())
	
	
	## Returns the full filepath to the user config
	static func get_user_config_path() -> String:
		if user_config_file_location.ends_with("/"):
			return user_config_file_location + user_config_file_name
		else:
			return user_config_file_location + "/" + user_config_file_name
	
	
	## Returns true if a notice can be shown
	static func can_show_notice(p_notice_id: String) -> bool:
		return notices_dont_show_again.has(p_notice_id)
	
	
	## Sets if a notice can be shown again
	static func set_notice_can_show(p_notice_id: String, p_can_show) -> void:
		if p_can_show:
			notices_dont_show_again.erase(p_notice_id)
		elif not notices_dont_show_again.has(p_notice_id):
			notices_dont_show_again.append(p_notice_id)


## Stores configuration for a WindowPopup instance
class PopupConfig:
	## Name of the node in the WindowPopups.tscn scene
	var node_name: String = ""
	
	## Name of the method used to apply the value
	var setter: String = ""
	
	## Maps each window to its associated node
	var nodes: Dictionary[Window, UIBase]
	
	## Maps each window to its setter callable
	var setter_callables: Dictionary[Window, Callable]
	
	## Maps each popups active state to the window
	var active_state: Dictionary[Window, bool]
	
	## Maps each window to its Promise
	var promises: Dictionary[Window, Promise]
	
	## Callables connected to the panels resolve signal
	var resolve_connections: Dictionary[Window, Callable]
	
	## Callables connected to the panels reject signal
	var reject_connections: Dictionary[Window, Callable]
	
	## Constructor
	func _init(p_node_name: String = "", p_setter: String = "") -> void:
		node_name = p_node_name
		setter = p_setter
