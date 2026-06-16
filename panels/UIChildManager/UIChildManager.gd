# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIChildManager extends UIPanel
## Displays a GBC's ChildManager via ChildManagerView


## The ChildManagerView used to displat the ChildManager
@onready var _component_manager: ChildManagerView = %ChildManagerView

## The OptionButton used to select the ChildManager
@onready var _child_manager_selection: OptionButton = %ChildManagerSelection

## The InvalidSelection panel shown when the component does not have any ChildManagers
@onready var _invalid_selection: PanelContainer = %InvalidSelection


## The current GBC Object
var _current_object: Object

## The current selected ChildManager
var _current_manager: ChildManager

## The ID of the previous selected ChildManager
var _previous_selected_manager: String = ""

## The ChildManager IDs as showin in ChildManagerSelection
var _manager_ids: Array[String]

## SignalGroup for Object
var _object_connections: SignalGroup = SignalGroup.new([
	_on_delete_requested
])


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UIChildManager")


## ready
func _ready() -> void:
	super._ready()
	
	_component_manager.set_new_button(%NewChild)
	_component_manager.set_delete_button(%DeleteChild)
	_component_manager.set_duplicate_button(%DuplicateChild)


## Sets the component to show ChildManagers from
func set_component(p_object: Object) -> void:
	if not Data.is_gbc_complient(p_object):
		p_object = null
	
	_object_connections.disconnect_object(_current_object)
	_current_object = p_object
	_object_connections.connect_object(_current_object)
	
	get_component_button().set_component(p_object)
	_component_manager.reset()
	
	_child_manager_selection.clear()
	_manager_ids.clear()
	_current_manager = null
	
	_invalid_selection.set_visible(true)
	_component_manager.set_visible(false)
	
	var is_valid: bool = is_instance_valid(_current_object)
	_child_manager_selection.set_disabled(not is_valid)
	
	
	if not is_valid:
		return
	
	var child_managers: Dictionary[String, ChildManager] = _current_object.get_settings().get_child_managers()
	
	if child_managers.size():
		_invalid_selection.set_visible(false)
		_component_manager.set_visible(true)
	else:
		return
	
	for manager_id: String in child_managers:
		_manager_ids.append(manager_id)
		_child_manager_selection.add_item(manager_id)
	
	var previous: ChildManager = _current_object.get_settings().get_child_manager(_previous_selected_manager)
	if is_instance_valid(previous):
		set_manager(previous)
	
	elif _manager_ids:
		set_manager(_current_object.get_settings().get_child_manager(_manager_ids[0]))


## Sets the displayed ChildManager
func set_manager(p_child_manager: ChildManager) -> void:
	if not is_instance_valid(p_child_manager):
		return
	
	if not is_instance_valid(_current_object) or _current_object != p_child_manager.get_parent():
		set_component(p_child_manager.get_parent())
	
	_component_manager.reset()
	_current_manager = p_child_manager
	
	var is_valid: bool = is_instance_valid(p_child_manager)
	
	if not is_valid:
		return
	
	_component_manager.mode_child_manager(p_child_manager)
	_child_manager_selection.select(_manager_ids.find(p_child_manager.get_id()))
	_previous_selected_manager = p_child_manager.get_id()


## Returns the current Object
func get_component() -> Object:
	return _current_object


## Returns the current ChildManager 
func get_manager() -> ChildManager:
	return _current_manager


## Seralizes this UIChildManager into a JSON complient dictonary
func serialize(p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> Dictionary:
	return super.serialize(p_flags).merged({
		"object": get_component_button().get_component_uuid()
	}.merged({
		"manager": get_manager().get_id()
	} if get_manager() else {}))


## Deserialize this UIChildManager
func deserialize(p_serialized_data: Dictionary, p_flags: Data.SerializationFlags = Data.SerializationFlags.NONE) -> void:
	super.deserialize(p_serialized_data, p_flags)
	
	get_component_button().look_for(type_convert(p_serialized_data.get("object"), TYPE_STRING))
	_previous_selected_manager = type_convert(p_serialized_data.get("manager"), TYPE_STRING)


## Called when the current Object emits a delete request
func _on_delete_requested() -> void:
	set_component(null)


## Called when an item is selected in ChildManagerSelection
func _on_child_manager_selection_item_selected(p_index: int) -> void:
	if not is_instance_valid(_current_object):
		return
	
	set_manager(_current_object.get_settings().get_child_manager(_manager_ids[p_index]))
