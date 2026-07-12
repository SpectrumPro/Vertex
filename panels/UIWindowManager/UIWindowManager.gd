# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIWindowManager extends UIPanel
## UIWindowManager for managing windows


## SettingsManagerView for the selected window
@export var settings_manager_multi_view: SettingsManagerMultiView

## The FocusWindow button
@export var focus_window_button: Button

## The DeleteWindowButton
@export var delete_window_button: Button


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UIWindowManager")


## Ready
func _ready() -> void:
	super._ready()
	
	Interface.window_added.connect(_add_window)
	Interface.window_removed.connect(_remove_window)
	
	for window: UIWindow in Interface.get_all_windows():
		_add_window(window)


## Called when a window is added
func _add_window(p_window: UIWindow) -> void:
	settings_manager_multi_view.add_manager(p_window.get_settings())


## Called when an item is removed
func _remove_window(p_window: UIWindow) -> void:
	settings_manager_multi_view.remove_manager(p_window.get_settings())


## Updates buttons disabled state
func _update_buttons() -> void:
	var selected_window: UIWindow = settings_manager_multi_view.get_selected_owner()
	var state: bool = selected_window == null
	
	focus_window_button.set_disabled(state)
	
	if selected_window and selected_window.is_window_root():
		state = true
	
	delete_window_button.set_disabled(state)


## Called when the AddWindow button is pressed
func _on_add_window_pressed() -> void:
	Interface.add_window()


## Called when the FocusWindow button is pressed
func _on_focus_window_pressed() -> void:
	for window: UIWindow in settings_manager_multi_view.get_selected_owners():
		window.set_window_visible(true)
		window.grab_focus()


## Called when the DeleteWindow button is pressed
func _on_delete_window_pressed() -> void:
	var selected_windows: Array = settings_manager_multi_view.get_selected_owners()
	
	if not selected_windows.size():
		return
	
	var title: String
	
	if selected_windows.size() > 1:
		title = str("Delete: ", selected_windows.size()," Windows?")
	else:
		title = str("Delete: ", selected_windows[0].get_window_title(), "?")
	
	Interface.create_popup_dialog(self).preset(UIPopupDialog.Preset.DELETE, title).then(func ():
		for window: UIWindow in selected_windows:
			Interface.remove_window(window)
		
		_update_buttons()
	)


## Called when the IdentifyWindows button is pressed
func _on_identify_windows_toggled(p_toggled_on: bool) -> void:
	if p_toggled_on:
		Interface.show_window_id()
	else:
		Interface.hide_window_id()
