# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInput extends Control
## DataInput base class

@warning_ignore_start("unused_parameter")

## Emitted when the value changed sucessfulley
signal value_change_sucess()


## The main Label
var _label: Label

## The LineEdit outline
var _outline: Panel

## The Control node to focus
var _focus_node: Control = self

## The Button used to show the quantity of modules
var _quantity_button: Button

## The currentl SettingsModle
var _module: SettingsModule

## All settings modules when multi editing
var _modules: Set = Set.new(TYPE_OBJECT)

## Number of virtual parameters to edit
var _virtual_parameters: int = 0

## Currently value unsaved state
var _unsaved: bool = false

## The DataType of this DataInput
var _data_type: Data.Type = Data.Type.NULL

## The SubType of this DataInput, if any
var _sub_type: int = Data.Sub.Type.NULL

## Editable state
var _editable: bool = true


## Resets this DataInput
func reset() -> void:
	if _module:
		_module.unsubscribe(_module_value_changed)
	
	if _outline:
		_outline.set_modulate(Color.TRANSPARENT)
	
	if _quantity_button:
		_quantity_button.set_text("")
	
	_unsaved = false
	_module = null
	_modules.clear()
	_virtual_parameters = 0
	
	_reset()


## Takes focus to the input
func focus() -> void:
	if is_instance_valid(_module) and _module.is_editable():
		_focus_node.grab_focus()


## Adds a SettingsModule to the list of moduled to multiedit
func add_module(p_module: SettingsModule) -> bool:
	if _modules.has(p_module) or _virtual_parameters:
		return false
	
	_modules.add(p_module)
	_update_quantity_button()
	
	return true


## Sets the SettingsMoudle(s) to edit
## p_virtual_parameters allows for virtual multi module editing without needing more then one module
## if p_virtual_parameters > 0: the returned datatype will be an Array[Variant]
## with one item for each virtual module. p_modules.size() must equal 1 if p_virtual_parameters > 0
func set_module(p_modules: Array[SettingsModule], p_virtual_parameters: int = 0) -> bool:
	p_virtual_parameters = clamp(p_virtual_parameters, 0, INF)
	
	if not p_modules.size() or not is_instance_valid(p_modules[0]):
		return false
	
	if p_modules.size() > 1 and p_virtual_parameters > 1:
		return false
	
	reset()
	_module = p_modules[0]
	_virtual_parameters = p_virtual_parameters
	
	for module: Variant in p_modules:
		if (
			is_instance_valid(module)
			and not _modules.has(module)
			and Data.do_types_match_base(module.get_data_type(), _data_type)
		):
			_modules.add(module)
	
	_module.subscribe(_module_value_changed)
	_settings_module_changed(_module)
	
	if _module.get_getter().is_valid():
		_module_value_changed(_module.get_getter().call())
	
	_update_quantity_button()
	set_editable(_module.is_editable())
	
	return true


## Shows or hides the label
func set_show_label(p_show_label: bool) -> void:
	if is_instance_valid(_label):
		_label.set_visible(p_show_label)


## Sets the label text
func set_label_text(p_label_text: String) -> void:
	if is_instance_valid(_label):
		_label.set_text(p_label_text) 


## Sets the editable state
func set_editable(p_editable: bool) -> void:
	_editable = p_editable
	_set_editable(_editable)


## Sets the value on the settings modules
func set_value(p_values: Array[Variant] = [[]]) -> void:
	if not _modules.size() or (p_values.size() != 1 and p_values.size() != get_num_modules()):
		return
	
	var use_single: bool = p_values.size() == 1
	
	if _virtual_parameters:
		if (not use_single) and p_values.size() != _virtual_parameters:
			return
		
		var return_values: Array
		
		if use_single:
			return_values.resize(_virtual_parameters)
			return_values.fill(p_values[0])
		else:
			return_values = p_values
		
		_handle_setter_return_value(_module.get_setter().call(return_values))
	
	else:
		var base_value: Variant = p_values[0]
		_handle_setter_return_value(_module.get_setter().callv(base_value))
		
		for index: int in range(1, _modules.size()):
			var indexed_value: Variant = base_value if use_single else p_values[index]
			_modules.get_at(index).get_setter().callv(indexed_value)


## Gets the SettingsMoudle
func get_module() -> SettingsModule:
	return _module


## Gets the label is_visible state
func get_show_label() -> bool:
	return _label.is_visible()


## Gets the label tetx
func get_label_text() -> String:
	return _label.get_text()


## Gets the data type
func get_data_type() -> Data.Type:
	return _data_type


## Gets the sub type
func get_sub_type() -> int:
	return _sub_type


## Gets the editable state
func get_editable() -> bool:
	return _editable


## Returns the number of modules being edited
## if _virtual_parameters > 0, _virtual_parameters will be returned
func get_num_modules() -> int:
	return _modules.size() if not _virtual_parameters else _virtual_parameters


## Handles the return value from the setter method, 
## updates outline based on a boolen return value. 
## If the return type is a Promise, it will be awaited then this method will be called again
## Sets the DataInputs input field back to the current value if setter fails
func _handle_setter_return_value(p_state: Variant) -> void:
	_unsaved = false
	Interface.kill_fade(_outline, "modulate")
	
	match typeof(p_state):
		TYPE_BOOL when p_state:
			_outline.set_modulate(ThemeManager.Colors.Statuses.Normal)
			value_change_sucess.emit()
		
		TYPE_BOOL when not p_state:
			_outline.set_modulate(ThemeManager.Colors.Statuses.Error)
			if _module.get_getter().is_valid():
				_module_value_changed(_module.get_getter().call())
		
		TYPE_OBJECT when p_state is Promise:
			_outline.set_modulate(ThemeManager.Colors.Statuses.Standby)
			p_state.then(_handle_setter_return_value)
		
		_:
			_outline.set_modulate(ThemeManager.Colors.Statuses.Normal)
			value_change_sucess.emit()
	
	await get_tree().create_timer(ThemeManager.Constants.Times.DataInputOutlineWait).timeout
	
	if not _unsaved:
		Interface.fade_property(_outline, "modulate", Color.TRANSPARENT, Callable(), ThemeManager.Constants.Times.DataInputOutlineFade)


## Marks this DataInput as unsaved
func _make_unsaved() -> void:
	if not _unsaved:
		_unsaved = true
		_outline.set_modulate(ThemeManager.Colors.Statuses.UnsavedData)


## Updated the number on the quantity button
func _update_quantity_button() -> void:
	if _quantity_button and _modules.size() > 1:
		_quantity_button.set_text(str("x", _modules.size()))


## Override this function to provide a SettingsModule to display
func _settings_module_changed(p_module: SettingsModule) -> void:
	pass


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ..._p_args) -> void:
	pass


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	pass


## Override for a reset function
func _reset() -> void:
	pass
