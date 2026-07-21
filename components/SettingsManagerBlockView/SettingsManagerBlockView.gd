# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SettingsManagerBlockView extends UIComponent
## Displays all SettingsModules in a SettingsManager 
## using SettingsManagerClassBlock components seprated by classname


## List of Data.Types that wont be displayed
@export var module_type_denylist: Array[Data.Type] = [Data.Type.ACTION]

## The VBox for all SettingsManagerClassBlock
@onready var _view_container: VBoxContainer = %ViewContainer


## All SettingsManager currently displayed
var _managers: Array[SettingsManager]

## Stores each ModuleView by its class
var _views_by_class: Dictionary[String, SettingsManagerClassBlock]


## Init
func _init() -> void:
	_set_class_name("SettingsManagerBlockView")


## Clears this SettingsManagerBlockView
func clear() -> void:
	for view: Control in _view_container.get_children():
		_view_container.remove_child(view)
		view.queue_free()
	
	_managers.clear()
	_views_by_class.clear()


## @deprecated(use set_managers() instead)
## Sets the SettingsManager
func set_manager(p_manager: SettingsManager) -> void:
	set_managers([p_manager])


## Sets the list of SettingsManagers to display
func set_managers(p_managers: Array[SettingsManager]) ->  void:
	clear()
	
	for manager: SettingsManager in p_managers:
		if not is_instance_valid(manager):
			continue
		
		_managers.append(manager)
		
		for classname: String in manager.get_inheritance_list():
			_create_class_block(classname)
	
		for child_manager_id: String in manager.get_child_managers():
			var child_manager: ChildManager = manager.get_child_manager(child_manager_id)
			var view: SettingsManagerClassBlock
			
			if child_manager.get_category() in _views_by_class:
				view = _views_by_class[child_manager.get_category()]
			else:
				view = _views_by_class[manager.get_inheritance_root()]
			
			view.show_child_manager(child_manager)
	
		for module: SettingsModule in manager.get_modules().values():
			if module_type_denylist.has(module.get_data_type()):
				continue
			
			var view: SettingsManagerClassBlock
			
			match module.get_data_type():
				Data.Type.SETTINGSMANAGER:
					var manager_view: SettingsManagerBlockView = UIDB.instance_component(SettingsManagerBlockView)
					
					_view_container.add_child(manager_view)
					manager_view.set_manager(module.get_getter().call())
				
				_:
					if module.get_visual_category() in _views_by_class:
						view = _views_by_class[module.get_visual_category()]
					else:
						view = _views_by_class[manager.get_inheritance_root()]
					
					if view.is_disabled():
						view.set_disabled(false)
					
					view.show_module(module)


## @deprecated(use get_managers() instead)
## Sets the SettingsManager
func get_manager() -> SettingsManager:
	return _managers[0] if _managers else null


## Returns all SettingsManager currenty displayed
func get_managers() -> Array[SettingsManager]:
	return _managers.duplicate()


## Creates a SettingsManagerClassBlock for the given class
func _create_class_block(p_classname: String) -> void:
	if _views_by_class.has(p_classname):
		return
	
	var view: SettingsManagerClassBlock = UIDB.instance_component(SettingsManagerClassBlock)
	
	_views_by_class[p_classname] = view
	_view_container.add_child(view)
	
	view.set_title(p_classname)
	view.set_disabled(true)
