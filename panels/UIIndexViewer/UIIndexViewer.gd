# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIIndexViewer extends UIPanel
## GUI element for managing a GBCIndex


## The ChildManagerView
@onready var _component_manager: ChildManagerView = %ChildManagerView


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("UIIndexViewer")


## ready
func _ready() -> void:
	super._ready()
	
	_component_manager.set_new_button(%NewComponent)
	_component_manager.set_delete_button(%DeleteComponent)
	_component_manager.set_duplicate_button(%DuplicateComponent)
	_component_manager.set_view_mode_button(%ViewModeButton)
	_component_manager.mode_gbc_index("")


## Called when a class is selected on the ComponentButton
func _on_component_button_class_selected(classname: String) -> void:
	var gbc_class: String = classname
	
	if classname:
		gbc_class = GlobalClassList.get_class_gbc_index(classname).get_base_class().get_global_name()
	
	_component_manager.mode_gbc_index(
		gbc_class, 
		classname
	)
