# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ComponentButton extends Button
## Button to select an GBC Object


## Emitted when a GBCIndex is selected
signal gbc_index_selected(index: GBCIndexConfig)

## Emitted when the object is changed
signal object_selected(object: Object)

## Emitted when a class is selected
signal class_selected(classname: String)

## Emitted when the status is changed
signal status_changed(status: Status)


## Enum for Mode
enum Mode {
	GBC_INDEX,		## Select a GBCIndexConfig
	GBC_OBJECT,		## Select an Object in a a given GBCIndex
	GBC_CLASS,		## Select a class in a a given GBCIndex
}

## Enum for Status
enum Status {
	DISABLED,			## ComponentButton has enabled == false
	EMPTY,				## No object or class asigned
	ASSIGNED,			## An object or class is assigned
	AWAITING_OBJECT		## Awating component request for an object
}


## Sets a filter to use when selecting Objects or Classes
@export var class_filter: Script

## Sets the base type assoicated with the GBCIndexConfig
@export var base_class: Script

## Allows Objects asigned to this button to be resolved 
@export var enable_resolve_mode: bool = false

## Button enabled state
@export var enabled: bool = false

## Mode to use when the button is pushed.
@export var mode: Mode = Mode.GBC_OBJECT

## The Panel used to display the text underline
@onready var _underline: Panel = %NameUnderline


## Selected GBCIndexConfig if any
var _gbc_index: GBCIndexConfig

## Selected Object if any
var _component: Object

## Selected classname if any
var _classname: String

## The orignal user defined text of this button
var _orignal_text: String

## The orignal user defined icon of this button
var _orignal_icon: Texture2D

## UUID of the EngineComponent to look for
var _look_for_component: String

## Current Status of this ComponentButton
var _status: Status = Status.DISABLED

## Current mode of this ComponentButton
var _mode: Mode = Mode.GBC_OBJECT

## Current enabled state of this ComponentButton
var _enabled: bool = false

## Signal connections for the EngineComponent
var _signal_group: SignalGroup = SignalGroup.new([
	_on_name_changed,
	_on_delete_requested,
])

var _status_colors: Dictionary[Status, Color] = {
	Status.DISABLED: ThemeManager.Colors.Statuses.Off,
	Status.EMPTY: ThemeManager.Colors.Statuses.Standby,
	Status.ASSIGNED: ThemeManager.Colors.Statuses.Normal,
	Status.AWAITING_OBJECT: ThemeManager.Colors.Statuses.Caution,
}

## ready
func _ready() -> void:
	_orignal_text = get_text()
	_orignal_icon = get_button_icon()
	set_enabled(enabled)
	set_mode(mode)


## Clears this ComponentButton
func clear() -> void:
	match _mode:
		Mode.GBC_INDEX:
			set_gbc_index(null)
		Mode.GBC_OBJECT:
			set_component(null)
		Mode.GBC_CLASS:
			set_class_name("")
	
	_restore_orignal()
	_update_status()


## Sets the mode for this ComponentButton
func set_mode(p_mode: Mode) -> void:
	_mode = p_mode
	clear()


## Sets the enabled state
func set_enabled(p_enabled) -> void:
	_enabled = p_enabled
	clear()


## Sets the GBCIndexConfig to display in the button
func set_gbc_index(p_gbc_index: GBCIndexConfig) -> void:
	if p_gbc_index == _gbc_index:
		return
	
	if _mode != Mode.GBC_INDEX:
		set_mode(Mode.GBC_INDEX)
	
	_gbc_index = p_gbc_index
	
	if is_instance_valid(_gbc_index):
		var gbc_classname: String = _gbc_index.get_base_class().get_global_name()
		set_text(gbc_classname)
		set_button_icon(UIDB.get_class_icon(gbc_classname))
	else:
		_restore_orignal()
	
	_update_status()
	gbc_index_selected.emit(_gbc_index)


## Sets the Object to display in the button
func set_component(p_component: Object) -> void:
	if p_component == _component:
		return
	
	if _mode != Mode.GBC_OBJECT:
		set_mode(Mode.GBC_OBJECT)
	
	_signal_group.disconnect_object(_component)
	_component = p_component
	_signal_group.connect_object(_component)
	
	if is_instance_valid(_component):
		set_text(_component.get_uname())
		set_button_icon(UIDB.get_class_icon(_component.get_class_name()))
	else:
		_restore_orignal()
	
	remove_look_for()
	_update_status()
	object_selected.emit(_component)


## Sets the classname to display in this object
func set_class_name(p_classname: String) -> void:
	if _classname == p_classname:
		return
	
	if _mode != Mode.GBC_CLASS:
		set_mode(Mode.GBC_CLASS)
	
	_classname = p_classname
	
	if _classname:
		set_text(_classname)
		set_button_icon(UIDB.get_class_icon(_classname))
	else:
		_restore_orignal()
	
	_update_status()
	class_selected.emit(_classname)


## Returns the selected GBCIndexConfig, or null
func get_gbc_index() -> GBCIndexConfig:
	return _gbc_index


## Returns the object
func get_component() -> Object:
	return _component


## Returns the UUID of the selected object
func get_component_uuid(p_allow_resolve_uuid: bool = true) -> String:
	return _component.get_uuid() if is_instance_valid(_component) else _look_for_component if p_allow_resolve_uuid else ""


## Returns the classname 
func get_classname() -> String:
	return _classname


## Removes the ComponentDB request for the object
func remove_look_for() -> void:
	if not _look_for_component:
		return
	
	CoreObjectDB.remove_request_static(_look_for_component, _on_component_found)
	_look_for_component = ""


## Looks for an object, or waits untill is added
func look_for(p_uuid: String) -> void:
	remove_look_for()
	
	if not p_uuid:
		return
	
	if _mode != Mode.GBC_OBJECT:
		set_mode(Mode.GBC_OBJECT)
	
	_look_for_component = p_uuid
	CoreObjectDB.request_component_static(_look_for_component, _on_component_found)
	
	_update_status()


## Updates the current status based on mode and selected item
func _update_status() -> void:
	match _mode:
		Mode.GBC_INDEX:
			if not _enabled:
				_status = Status.DISABLED
			elif _gbc_index:
				_status = Status.ASSIGNED
			elif not _gbc_index:
				_status = Status.EMPTY
			
		Mode.GBC_OBJECT:
			if not _enabled:
				_status = Status.DISABLED
			elif _component:
				_status = Status.ASSIGNED
			elif not _component and _look_for_component:
				_status = Status.AWAITING_OBJECT
			elif not _component:
				_status = Status.EMPTY

		Mode.GBC_CLASS:
			if not _enabled:
				_status = Status.DISABLED
			elif _classname:
				_status = Status.ASSIGNED
			elif not _classname:
				_status = Status.EMPTY
	
	_underline.set_modulate(_status_colors[_status])
	status_changed.emit(_status)


## Restores the orignal text and icon
func _restore_orignal() -> void:
	set_text(_orignal_text)
	set_button_icon(_orignal_icon)


## Called if ComponentDB find the component
func _on_component_found(p_component: Object) -> void:
	if class_filter and not p_component.get_class_tree().has(class_filter.get_global_name()):
		return
	
	set_component(p_component)


## Called when the components name is changed
func _on_name_changed(p_new_name: String) -> void:
	text = p_new_name


## Called when the component is to be deleted
func _on_delete_requested(_p_component: Object) -> void:
	var uuid: String = _component.get_uuid()
	set_component(null)
	look_for(uuid)


## Called when the button is pressed
func _on_pressed() -> void:
	if not _enabled:
		return
	
	match _mode:
		Mode.GBC_INDEX:
			Popups.ObjectSelector_gbc_index(
				self
			).then(func (p_index: GBCIndexConfig):
				set_gbc_index(p_index)
			)
		
		Mode.GBC_OBJECT when is_instance_valid(base_class):
			Popups.ObjectSelector(
				self, 
				base_class, 
				class_filter.get_global_name() if class_filter else StringName()
			).then(func (p_component: Object):
				set_component(p_component)
			)
		
		Mode.GBC_OBJECT when not is_instance_valid(base_class):
			Popups.ObjectSelector_gbc_object(
				self
			).then(func (p_component: Object):
				set_component(p_component)
			)
		
		Mode.GBC_CLASS:
			Popups.ObjectSelector_gbc_class(
				self
			).then(func (p_class: String):
				set_class_name(p_class)
			)


## Called for all gui inputs on this button
func _on_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.is_pressed():
		p_event = p_event as InputEventMouseButton
		
		match p_event.button_index:
			MOUSE_BUTTON_RIGHT:
				if _enabled and _mode == Mode.GBC_OBJECT and is_instance_valid(_component):
					Popups.USettingsManager(self, _component.get_settings())
