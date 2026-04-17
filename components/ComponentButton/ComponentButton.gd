# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name ComponentButton extends Button
## Button to select an GBC Object


## Emitted when the object is changed
signal object_selected(object: Object)


## Classname filter to search for
@export var class_filter: Script

## The base type class for the object picker
@export var base_class: Script

## Enables this button to follow global store mode
@export var enable_resolve_mode: bool = false

## Button enabled state
@export var enabled: bool = false

## Nodes group
@export_group("nodes")

## The control to act as the status label
@export var underline: Control


## The current object
var _component: Object = null

## The orignal user defined text of this button
var _orignal_text: String

## The orignal user defined icon of this button
var _orignal_icon: Texture2D

## UUID of the EngineComponent to look for
var _look_for_component: String

## Signal connections for the EngineComponent
var _signal_group: SignalGroup = SignalGroup.new([
	_on_name_changed,
	_on_delete_requested,
])


## ready
func _ready() -> void:
	_orignal_text = get_text()
	_orignal_icon = get_button_icon()
	set_enabled(enabled)


## Sets the select object
func set_component(p_component: Object) -> void:
	if p_component == _component:
		return
	
	_signal_group.disconnect_object(_component)
	_component = p_component
	_signal_group.connect_object(_component)
	
	if not is_instance_valid(_component):
		set_text(_orignal_text)
		set_button_icon(_orignal_icon)
		
		underline.set_modulate(ThemeManager.Colors.Statuses.Standby)
	
	else:
		set_text(_component.get_uname())
		set_button_icon(UIDB.get_class_icon(_component.get_class_name()))
		
		underline.set_modulate(ThemeManager.Colors.Statuses.Normal)
	
	remove_look_for()
	object_selected.emit(_component)


## Returns the object
func get_component() -> Object:
	return _component


## Returns the UUID of the component, or ""
func get_component_uuid(p_allow_resolve_uuid: bool = true) -> String:
	return _component.get_uuid() if is_instance_valid(_component) else _look_for_component if p_allow_resolve_uuid else ""


## Removes the ComponentDB request for the object
func remove_look_for() -> void:
	if _look_for_component:
		ObjectDB.remove_request_static(_look_for_component, _on_component_found)
		_look_for_component = ""


## Looks for an object, or waits untill is added
func look_for(p_uuid: String) -> void:
	remove_look_for()
	_look_for_component = p_uuid
	
	if not p_uuid:
		return
	
	underline.set_modulate(ThemeManager.Colors.Statuses.Caution)
	ObjectDB.request_component_static(_look_for_component, _on_component_found)


## Sets the enabled state
func set_enabled(p_enabled) -> void:
	enabled = p_enabled
	
	if enabled and _component:
		underline.set_modulate(ThemeManager.Colors.Statuses.Normal)
	elif enabled and not _component:
		underline.set_modulate(ThemeManager.Colors.Statuses.Standby)
	elif enabled and not _component and _look_for_component:
		underline.set_modulate(ThemeManager.Colors.Statuses.Caution)
	elif not enabled:
		underline.set_modulate(ThemeManager.Colors.Statuses.Off)


## Called if ComponentDB find the component
func _on_component_found(p_component: Object) -> void:
	if p_component.get_class_tree().has(class_filter.get_global_name()):
		set_component(p_component)


## Called when the components name is changed
func _on_name_changed(p_new_name: String) -> void:
	text = p_new_name


## Called when the component is to be deleted
func _on_delete_requested() -> void:
	var uuid: String = _component.get_uuid()
	set_component(null)
	look_for(uuid)


## Called when the button is pressed
func _on_pressed() -> void:
	if not enabled:
		return
	
	if base_class:
		@warning_ignore("incompatible_ternary")
		var filter: Variant = class_filter.get_global_name() if class_filter else ""
		
		Popups.ObjectSelector(self, base_class, filter).then(func (p_component: Object):
			set_component(p_component)
		)
	else:
		Popups.ObjectSelector_gbc_object(self).then(func (p_component: Object):
			set_component(p_component)
		)
