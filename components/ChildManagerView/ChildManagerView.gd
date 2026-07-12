# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ChildManagerView extends UIComponent
## Manages child objects via a ChildManager and or a GBCIndexConfig


## Enum for mode
enum Mode {
	NONE,			## No selected mode
	GBCINDEX,		## Use a GBCIndexConfig to manage objects
	CHILDMANAGER,	## Use a custom ChildManager to manage objects
}


## The SettingsManagerMultiView
@onready var _settings_manager_multi_view: SettingsManagerMultiView = %SettingsManagerMultiView


## The Mode of this ComponentManagerView
var _mode: Mode = Mode.NONE

## The GBCIndexConfig when using Mode.GBCINDEX
var _gbc_index_config: GBCIndexConfig

## The ChildManager used in either mode
var _child_manager: ChildManager

## The class filter used when in Mode.GBCIndex
var _class_filter: String

## The NewComponent Button
var _new_button: Button

## The DeleteComponent Button
var _delete_button: Button

## The DuplicateComponent Button
var _duplicate_button: Button

## The ViewModeOption OptionButton
var _view_mode_button: OptionButton


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	
	_set_class_name("ChildManagerView")


## Sets mode to Mode.GBCIndex
func mode_gbc_index(p_index_class: String, p_class_filter: String = "") -> void:
	reset()
	_mode = Mode.GBCINDEX
	
	if not Data.has_gbc_config(p_index_class):
		return
	
	_gbc_index_config = Data.get_gbc_config(p_index_class)
	_child_manager = _gbc_index_config.get_child_manager()
	
	if p_class_filter:
		_class_filter = p_class_filter
	else:
		_class_filter = str(_child_manager.get_child_class().get_global_name())
	
	_gbc_index_config.get_objectdb().request_class_callback(_class_filter, _class_callback)
	reload()


## Sets mode to Mode.CHILDMANAGER
func mode_child_manager(p_child_manager: ChildManager) -> void:
	reset()
	_mode = Mode.CHILDMANAGER
	
	if not is_instance_valid(p_child_manager):
		return
	
	_child_manager = p_child_manager
	_class_filter = str(_child_manager.get_child_class().get_global_name())
	
	_child_manager.modification_callback.connect(_class_callback)
	reload()


## Reloads all objects shown in this ComponentManagerView
func reload() -> void:
	_settings_manager_multi_view.clear()
	
	match _mode:
		Mode.GBCINDEX:
			_class_callback(_gbc_index_config.get_objectdb().get_components_by_classname(_class_filter), [])
		
		Mode.CHILDMANAGER:
			_class_callback(_child_manager.get_children(), [])
	
	_update_buttons()


## Resets this ComponentManagerView
func reset() -> void:
	_settings_manager_multi_view.clear()
	
	match _mode:
		Mode.GBCINDEX when is_instance_valid(_gbc_index_config):
			_gbc_index_config.get_objectdb().remove_class_callback(_class_filter, _class_callback)
		
		Mode.CHILDMANAGER when is_instance_valid(_child_manager):
			_child_manager.modification_callback.disconnect(_class_callback)
	
	_gbc_index_config = null
	_child_manager = null
	_class_filter = ""
	_update_buttons()


## Sets the ViewMode on the SettingsManagerMultiView
func set_view_mode(p_view_mode: SettingsManagerMultiView.ViewMode):
	_settings_manager_multi_view.set_view_mode(p_view_mode)


## Sets the NewComponent Button
func set_new_button(p_button: Button) -> void:
	if is_instance_valid(_new_button):
		_new_button.pressed.disconnect(_on_new_button_pressed)
	
	_new_button = p_button
	
	if is_instance_valid(_new_button):
		_new_button.pressed.connect(_on_new_button_pressed)
	
	queue(_update_buttons)


## Sets the DeleteComponent Button
func set_delete_button(p_button: Button) -> void:
	if is_instance_valid(_delete_button):
		_delete_button.pressed.disconnect(_on_delete_button_pressed)
	
	_delete_button = p_button
	
	if is_instance_valid(_delete_button):
		_delete_button.pressed.connect(_on_delete_button_pressed)
	
	queue(_update_buttons)


## Sets the DuplicateComponent Button
func set_duplicate_button(p_button: Button) -> void:
	if is_instance_valid(_duplicate_button):
		_duplicate_button.pressed.disconnect(_on_duplicate_button_pressed)
	
	_duplicate_button = p_button
	
	if is_instance_valid(_duplicate_button):
		_duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	
	queue(_update_buttons)


## Sets the ViewModeButton
func set_view_mode_button(p_button: OptionButton) -> void:
	if is_instance_valid(_view_mode_button):
		_view_mode_button.item_selected.disconnect(_on_view_mode_button_item_selected)
	
	_view_mode_button = p_button
	
	if is_instance_valid(_view_mode_button):
		_view_mode_button.item_selected.connect(_on_view_mode_button_item_selected)
		_view_mode_button.clear()
		
		for view_mode: String in SettingsManagerMultiView.ViewMode.keys():
			_view_mode_button.add_item(view_mode.capitalize())
		
		_view_mode_button.select(_settings_manager_multi_view.get_view_mode())


## Returns the NewComponent Button
func get_new_button() -> Button:
	return _new_button


## Returns the DeleteComponent Button
func get_delete_button() -> Button:
	return _delete_button


## Returns the DuplicateComponent Button
func get_duplicate_button() -> Button:
	return _duplicate_button


## Returns the ViewModeButton
func get_view_mode_button() -> OptionButton:
	return _view_mode_button


## Returns the internal SettingsManagerMultiView
func get_settings_manager_multi_view() -> SettingsManagerMultiView:
	return _settings_manager_multi_view


## Called when objects are added or removed from
func _class_callback(p_added: Array, p_removed: Array) -> void:
	for component: Object in p_added:
		_settings_manager_multi_view.add_manager(component.get_settings())
	
	for component: Object in p_removed:
		_settings_manager_multi_view.remove_manager(component.get_settings())


## Updates the enabled state on all buttons based on selected items
func _update_buttons() -> void:
	var addition_allowed: bool = false
	var deletion_allowed: bool = false
	var duplication_allowed: bool = false
	var has_selected: bool = _settings_manager_multi_view.is_any_selected()
	
	if is_instance_valid(_child_manager):
		addition_allowed = _child_manager.is_addition_allowed()
		deletion_allowed = _child_manager.is_deletion_allowed()
		duplication_allowed = _child_manager.is_duplication_allowed()
	
	_new_button.set_disabled(not addition_allowed)
	_delete_button.set_disabled(not (deletion_allowed and has_selected))
	_duplicate_button.set_disabled(not (duplication_allowed and has_selected))


## Called when the NewComponent Button is pressed
func _on_new_button_pressed() -> void:
	Popups.ObjectSelector_class(self, _child_manager.get_index_class(), _class_filter).then(func (p_classname: String):
		_child_manager.create_child(p_classname)
	)


## Called when the DeleteComponent Button is presse
func _on_delete_button_pressed() -> void:
	if not is_instance_valid(_child_manager):
		return
	
	var child_manager: ChildManager = _child_manager
	var selected: Array[Object] = _settings_manager_multi_view.get_selected_owners()
	
	Popups.confirm_delete_components(self, selected, false).then(func ():
		if is_instance_valid(child_manager):
			child_manager.remove_children(selected)
	)


## Called when the DuplicateComponent Button is pressed
func _on_duplicate_button_pressed() -> void:
	if not is_instance_valid(_child_manager):
		return
	
	var selected: Object = _settings_manager_multi_view.get_selected_owner()
	
	if is_instance_valid(selected):
		_child_manager.duplicate_child(selected)


## Called when the ViewModeButton changed selected item
func _on_view_mode_button_item_selected(p_item: int) -> void:
	set_view_mode(p_item as SettingsManagerMultiView.ViewMode)
