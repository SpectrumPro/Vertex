# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SettingsManagerMultiView extends UIComponent
## Displays mutiple SettingsManagers in a SettingsManager TableView and BlockView view, 
## syncing selection between both


## Emitted when the selection is changed
signal selection_changed(selected_managers: Array)


## Emum for ViewMode
enum ViewMode {
	TABLE,		## Show only the table, with all SettingsModules
	COMBINED	## Show table and block view, with table only showing Primary modules
}


## The SettingsManagerTableView
@onready var _table_view: SettingsManagerTableView = %SettingsManagerTableView

## The SettingsManagerBlockView
@onready var _block_view: SettingsManagerBlockView = %SettingsManagerBlockView


## Current ViewMode
var _view_mode: ViewMode = ViewMode.COMBINED


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	
	_set_class_name("SettingsManagerMultiView")


## Adds a manager
func add_manager(p_manager: SettingsManager) -> void:
	_table_view.add_manager(p_manager)


## Removes a manager
func remove_manager(p_manager: SettingsManager) -> void:
	_table_view.remove_manager(p_manager)


## Selects a manager
func select_manager(p_manager: SettingsManager) -> void:
	_table_view.select_managers([p_manager])


## Resets 
func clear() -> void:
	_table_view.clear()
	_block_view.clear()


## Sets the ViewMode
func set_view_mode(p_view_mode: ViewMode) -> void:
	_view_mode = p_view_mode
	
	match _view_mode:
		ViewMode.TABLE:
			_table_view.show()
			_block_view.hide()
			
			_table_view.set_column_display(SettingsManagerTableView.ColumnDisplay.ALL)
		
		ViewMode.COMBINED:
			_table_view.show()
			_block_view.show()
			
			_table_view.set_column_display(SettingsManagerTableView.ColumnDisplay.PRIMARY)


## Returns the current ViewMode
func get_view_mode() -> ViewMode:
	return _view_mode


##0 Returns the last selected SettingsManager
func get_selected_manager() -> SettingsManager:
	if not _table_view.is_any_selected():
		return null
	
	return _table_view.get_selected_managers()[0]


## Returns all selected SettingsManagers
func get_selected_managers() -> Array[SettingsManager]:
	return _table_view.get_selected_managers()


## Gets the owner of the selected SettingsManager, or null
func get_selected_owner() -> Object:
	var selected_manager: SettingsManager = get_selected_manager()
	
	if is_instance_valid(selected_manager):
		return selected_manager.get_owner()
	else:
		return null


## Returns the owners of all selected SettingsManagers
func get_selected_owners() -> Array[Object]:
	var result: Array[Object]
	
	for manager: SettingsManager in _table_view.get_selected_managers():
		result.append(manager.get_owner())
	
	return result


## Returns true if there is a selected SettingsManager
func is_any_selected() -> bool:
	return _table_view.is_any_selected()


## Called when the selection changes in the TableView
func _on_settings_manager_table_view_selection_changed(selected_managers: Array) -> void:
	if not selected_managers:
		_block_view.clear()
	else:
		_block_view.set_manager(selected_managers[0])
	
	selection_changed.emit(selected_managers)
