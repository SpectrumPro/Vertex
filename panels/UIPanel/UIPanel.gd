# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIPanel extends UIBase
## Base class for all UI Panels


## Emitted when the panel requests to be moved when not in edit mode, by is the distance
signal request_move(by: Vector2)

## Emitted when the panel requests to be resized when not in edit mode, to is the new size
signal request_resize(by: Vector2)

## Emitted when the edit mode is toggled
signal edit_mode_toggled(state: bool)

## Emitted when the menu var visibility changes
signal menu_bar_visibility_changed(bar_visible: bool)

## Emitted when the close button is pressed
signal close_request()


## Display mode for this panel
@export var display_mode: DisplayMode = DisplayMode.Panel : set = set_display_mode

## All the nodes whos visibility should be toggled with edit mode
@export var edit_mode_nodes: Array[Control] = []

## All buttons that can have a shortcut asigned to them
@export var buttons: Array[Button]


## Display mode for this panel
enum DisplayMode {Panel, Popup, Imbed}

## Min size for UIPanels
const MinSize: Vector2 = Vector2(240, 160)


## The PanelMenuBar
var _menu_bar: PanelMenuBar

## The UIPanelEditControls
var _edit_controls: UIPanelEditControls

## The ComponentButton
var _component_button: ComponentButton

## Edit mode state
var _edit_mode: bool = false

## Edit mode disabled state
var _edit_mode_disabled: bool = false

## RefMap for Button: ButtonName
var _buttons_map: RefMap = RefMap.new()

## Stores all buttons and thier InputAction connections
var _button_actions: Dictionary[Button, Array]

## Mouse warp distance
var _mouse_warp: Vector2


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UIPanel")
	
	_settings.register_setting("show_menu_bar", Data.Type.BOOL, set_menu_bar_visible, get_menu_bar_visible, [menu_bar_visibility_changed]
	).display("UIPanel", 0)
	


## ready
func _ready() -> void:
	var menu_bar: PanelMenuBar = %PanelMenuBar
	
	if is_instance_valid(menu_bar):
		set_menu_bar(%PanelMenuBar)
	else:
		set_edit_controls(%EditControls)
		set_component_button(%ComponentButton)
	
	set_edit_mode(false)
	
	for button: Button in buttons:
		_buttons_map.map(button, button.name)
		_button_actions[button] = []
	
	if custom_minimum_size != Vector2.ZERO:
		custom_minimum_size = MinSize
	
	if get_parent() is UIWindow:
		set_display_mode(DisplayMode.Imbed)
	
	if _menu_bar:
		_menu_bar._owner = self


## Causes this panel to flash for a breef moment to get the users attenction
func flash() -> void:
	modulate = ThemeManager.Colors.UIPanelFlashColor
	Interface.fade_property(self, "modulate", Color.WHITE, Callable(), ThemeManager.Constants.Times.UIPanelFlashTime)


## Makes this UIBase take focus
func focus() -> void:
	if get_focus_mode_with_override():
		grab_focus()


## Adds a button to allow shortcuts to be added
func add_button(p_button: Button) -> bool:
	if _buttons_map.has_left(p_button):
		return false
	
	_buttons_map.map(p_button, p_button.get_name())
	_button_actions[p_button] = []
	return true


## Adds mutiple buttons for shortcuts
func add_buttons(p_buttons: Array) -> void:
	for button: Variant in p_buttons:
		if button is Button:
			add_button(button)


## Removes a button
func remove_button(p_button: Button) -> bool:
	if not _buttons_map.has_left(p_button):
		return false
	
	remove_all_button_actions(p_button)
	_buttons_map.erase_left(p_button)
	_button_actions.erase(p_button)
	
	return true


## Removes mutiple buttons for shortcuts
func remove_buttons(p_buttons: Array) -> void:
	for button: Variant in p_buttons:
		if button is Button:
			remove_button(button)


## Asigned an InputAction to a button
func asign_button_action(p_button: Button, p_action: InputAction) -> bool:
	if not _button_actions.has(p_button) or _button_actions[p_button].has(p_action):
		return false
	
	if not p_action.connect_button(p_button):
		return false
	
	_button_actions[p_button].append(p_action)
	return true


## Asigned an InputAction to a button
func remove_button_action(p_button: Button, p_action: InputAction) -> bool:
	if not _button_actions.has(p_button) or not _button_actions[p_button].has(p_action):
		return false
	
	_button_actions[p_button].erase(p_action)
	return p_action.disconnect_button(p_button)


## Removes all the actions from a button
func remove_all_button_actions(p_button: Button) -> bool:
	if not _button_actions.has(p_button):
		return false
	
	for action: InputAction in _button_actions[p_button]:
		action.disconnect_button(p_button)
	
	_button_actions.erase(p_button)
	return true


## Shows or hides the panels settings
func show_settings() -> void:
	Interface.show_window_popup(UIPanelSettings, self, self)


## Detaches the menu bar
func detatch_menu_bar() -> PanelMenuBar:
	if not is_instance_valid(_menu_bar):
		return null
	
	_menu_bar.set_popup_style(true)
	_menu_bar.get_parent().remove_child(_menu_bar)
	_menu_bar.set_owner(null)
	return _menu_bar


## Gets the current DisplayMode
func get_display_mode() -> DisplayMode:
	return display_mode


## Gets the edit mode state
func get_edit_mode() -> bool:
	return _edit_mode


## Gets the EditMode disabled state
func get_edit_mode_disabled() -> bool:
	return _edit_mode_disabled


## Gets the panels menu bar
func get_menu_bar() -> PanelMenuBar:
	return _menu_bar


## Gets the menu bars visible state
func get_menu_bar_visible() -> bool:
	if is_instance_valid(_menu_bar):
		return _menu_bar.visible
	else:
		return false


## Returns the UIPanelEditControls for this UIPanel
func get_edit_controls() -> UIPanelEditControls:
	return _edit_controls


## Returns the ComponentButton for this UIPanel
func get_component_button() -> ComponentButton:
	return _component_button


## Gets all the buttons
func get_buttons() -> Array:
	return _buttons_map.get_left()


## Gets all the InputActions asigned to a button
func get_button_actions(button: Button) -> Array:
	return _button_actions.get(button, [])


## Sets the display mode
func set_display_mode(p_dispaly_mode: DisplayMode) -> void:
	display_mode = p_dispaly_mode
	
	if not _edit_controls:
		return
	
	match display_mode:
		DisplayMode.Panel:
			_edit_controls.show_close = false
			_edit_controls.show_handle = true
			add_theme_stylebox_override("panel", ThemeManager.StyleBoxes.UIPanelBase)
		
		DisplayMode.Popup:
			_edit_controls.show_close = true
			_edit_controls.show_handle = true
			add_theme_stylebox_override("panel", ThemeManager.StyleBoxes.UIPanelPopup)
		
		DisplayMode.Imbed:
			_edit_controls.show_close = false
			_edit_controls.show_handle = false
			add_theme_stylebox_override("panel", ThemeManager.StyleBoxes.UIPanelImbed)


## Sets the edit mode state
func set_edit_mode(p_state: bool) -> void:
	_edit_mode = p_state
	
	for control: Control in edit_mode_nodes:
		Interface.set_visible_and_fade(control, _edit_mode)
	
	_edit_mode_toggled(_edit_mode)
	edit_mode_toggled.emit(_edit_mode)


## Disables or enabled edit mode
func set_edit_mode_disabled(p_disabled: bool) -> void:
	if _edit_mode:
		set_edit_mode(false)
	
	_edit_mode_disabled = p_disabled
	
	if is_instance_valid(_edit_controls):
		_edit_controls.edit_button.disabled = _edit_mode_disabled


## Sets the PanelMenuBar. Also sets UIPanelEditControls
func set_menu_bar(p_menu_bar: PanelMenuBar) -> void:
	_menu_bar = p_menu_bar
	set_edit_controls(_menu_bar.get_edit_controls())
	set_component_button(_menu_bar.get_component_button())


## Sets the menu bar visible state
func set_menu_bar_visible(p_visable: bool) -> void:
	if _menu_bar:
		_menu_bar.visible = p_visable
		menu_bar_visibility_changed.emit(_menu_bar.visible)


## Sets the move and resize handle
func set_edit_controls(p_edit_controls: UIPanelEditControls) -> void:
	if is_instance_valid(_edit_controls): 
		_edit_controls.move_resize_handle.gui_input.disconnect(_on_move_resize_gui_input)
		_edit_controls.edit_button.toggled.disconnect(_on_edit_button_toggled)
		_edit_controls.settings_button.pressed.disconnect(_on_settings_button_pressed)
		_edit_controls.close_button.pressed.disconnect(_on_close_button_pressed)
	
	_edit_controls = p_edit_controls
	
	if is_instance_valid(_edit_controls):
		_edit_controls.move_resize_handle.gui_input.connect(_on_move_resize_gui_input)
		_edit_controls.edit_button.toggled.connect(_on_edit_button_toggled)
		_edit_controls.settings_button.pressed.connect(_on_settings_button_pressed)
		_edit_controls.close_button.pressed.connect(_on_close_button_pressed)
		
		_edit_controls.show_close = (display_mode == DisplayMode.Popup)
		set_display_mode(get_display_mode())


## Sets the ComponentButton
func set_component_button(p_button: ComponentButton) -> void:
	_component_button = p_button


## Serializes this UIPanel into a dictonary
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	var button_actions: Dictionary[String, Array]
	
	for button: Button in _buttons_map.get_left():
		var actions: Array[String]
		for action: InputAction in get_button_actions(button):
			actions.append(action.uuid())
		
		button_actions[button.name] = actions
	
	return super.serialize(p_flags).merged({
		"button_actions": button_actions,
		"show_menu_bar": get_menu_bar_visible()
	})


## Loads this UIPanel from dictionary
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	set_menu_bar_visible(type_convert(p_serialized_data.get("show_menu_bar", get_menu_bar_visible()), TYPE_BOOL))
	
	var button_actions: Dictionary = type_convert(p_serialized_data.get("button_actions"), TYPE_DICTIONARY)
	
	for button_name: Variant in button_actions.keys():
		if not button_name is String or not _buttons_map.has_right(button_name) or not button_actions[button_name] is Array:
			return
		
		for action_uuid: Variant in button_actions[button_name]:
			if action_uuid is String:
				var button: Button = _buttons_map.right(button_name)
				var action: InputAction = InputServer.get_input_action(action_uuid)
				
				if action:
					asign_button_action(button, action)


## Override this function to change state when edit mode is toggled
func _edit_mode_toggled(_p_state: bool) -> void:
	pass


## Called for GUI inputs on the move resize handle
func _on_move_resize_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseMotion:
		p_event = p_event as InputEventMouseMotion
		
		var relative: Vector2 = p_event.screen_relative - _mouse_warp
		_mouse_warp = Vector2.ZERO
		
		match p_event.button_mask:
			MOUSE_BUTTON_MASK_LEFT:
				request_move.emit(relative)
				
				if display_mode == DisplayMode.Popup:
					position.x = clamp(position.x + relative.x, 0, get_parent_control().size.x - size.x)
					position.y = clamp(position.y + relative.y, 0, get_parent_control().size.y - size.y)
					move_to_front()                                                                                                                        
			
			MOUSE_BUTTON_MASK_RIGHT:
				request_resize.emit(relative)
				
				if display_mode == DisplayMode.Popup:
					size.x = clamp(size.x + relative.x, 0, get_parent_control().size.x - position.x)
					size.y = clamp(size.y + relative.y, 0, get_parent_control().size.y - position.y)
					
					var gp: Vector2 = get_global_mouse_position()
					if gp.y <= 0:
						_mouse_warp = Vector2(0, _edit_controls.move_resize_handle.global_position.y)
						Input.warp_mouse(Vector2(gp.x, _mouse_warp.y))
					
					move_to_front()                                                                                                                        


## Called when the edit mode button is toggled
func _on_edit_button_toggled(p_state: bool) -> void:
	set_edit_mode(p_state)


## Called when the settings button is toggled
func _on_settings_button_pressed() -> void:
	show_settings()


## Called when the close button is pressed
func _on_close_button_pressed() -> void:
	close_request.emit()


## Disables all the buttons in the given array
static func disable_button_array(p_buttons: Array[Button]) -> void:
	set_button_array_enabled(p_buttons, true)


## Enables all the buttons in the given array
static func enable_button_array(p_buttons: Array[Button]) -> void:
	set_button_array_enabled(p_buttons, false)


## Sets an array of buttons enabled or disabled
static func set_button_array_enabled(p_buttons: Array, p_disabled: bool) -> void:
	for button: Button in p_buttons:
		button.disabled = p_disabled
