# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UISettingsManager extends UIPanel
## UISettingsManager


## The ComponentButton
@export var component_button: ComponentButton

## The SettingsManagerView
@export var settings_manager_view: SettingsManagerView


## The current selected GBC component
var _component: Object

## The current selected SettingsManager
var _manager: SettingsManager


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UISettingsManager")


## Sets the component to display
func set_component(p_component: Object) -> void:
	_component = p_component
	component_button.set_component(p_component)
	
	if not is_instance_valid(p_component):
		return
	
	set_manager(p_component.get_settings())


## Sets the component
func set_manager(p_manager: SettingsManager) -> void:
	if p_manager.get_owner() != _component:
		set_component(p_manager.get_owner())
		return
	
	_manager = p_manager
	
	if not is_instance_valid(_manager):
		settings_manager_view.reset()
		return
	
	settings_manager_view.set_manager(_manager)


## Returns the current selected GBC component
func get_component() -> Object:
	return _component


## Gets the current component
func get_maneger() -> SettingsManager:
	return _manager
