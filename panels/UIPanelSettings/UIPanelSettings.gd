# Copyright (c) 2025 Liam Sherwin. All rights reserved. 
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later. 
# See the LICENSE file for details.

class_name UIPanelSettings extends UIPanel
## Settings for UI Panels


## Emitted when the panel is changed
signal panel_changed(panel)


## UIPanelSettingsShortcuts Settings Page
@export var _shortcuts_panel: UIPanelSettingsShortcuts

## The SettingsManagerBlockView for settings
@export var _settings_panel: SettingsManagerBlockView


## Max History Length
const MAX_HISTORY_LENGTH: int = 5


## The current UIPanel
var _panel: UIPanel

## History of all UIPanels shown
var _panel_history: Array[UIPanel]


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UIPanelSettings")


## Ready
func _ready() -> void:
	super._ready()
	get_edit_controls().back_button.pressed.connect(_on_back_button_pressed)


## Sets the panel
func set_panel(p_panel: UIPanel, add_to_history: bool = true) -> void:
	_panel = p_panel
	_settings_panel.set_manager(_panel.get_settings())
	
	if add_to_history:
		_panel_history.append(_panel)
		
		if _panel_history.size() > MAX_HISTORY_LENGTH:
			_panel_history.pop_front()
	
	get_edit_controls().set_show_back(_panel_history.size() > 1)
	panel_changed.emit(_panel)


## Gets the UIPanelSettingsShortcuts Settings page
func get_shortcut_settings() -> UIPanelSettingsShortcuts:
	return _shortcuts_panel


## Called when the back button is pressed
func _on_back_button_pressed() -> void:
	if _panel_history.size() <= 1:
		return
	
	_panel_history.pop_back()
	set_panel(_panel_history[_panel_history.size() - 1], false)


## Called when the visibility is changed
func _on_visibility_changed() -> void:
	if not is_node_ready():
		return
	
	if not visible:
		_panel_history.clear()
		get_edit_controls().set_show_back(false)
