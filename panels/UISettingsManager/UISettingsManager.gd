# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UISettingsManager extends UIPanel
## UISettingsManager


## The ComponentButton
@export var component_button: ComponentButton

## The SettingsManagerView
@export var settings_manager_view: SettingsManagerView


## The current selected component
var _manager: SettingsManager


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UISettingsManager")


## Sets the component
func set_manager(p_manager: SettingsManager) -> void:
	_manager = p_manager
	component_button.set_text(_manager.get_inheritance_child())
	
	if not is_instance_valid(_manager):
		settings_manager_view.reset()
		return
	
	settings_manager_view.set_manager(_manager)


## Gets the current component
func get_maneger() -> SettingsManager:
	return _manager
