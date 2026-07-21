# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SettingsManagerTableView extends UIComponent
## Displays SettingsManagers in a table view, with one column per SettingsModule


## Emitted when the selection is changed
signal selection_changed(selected_managers: Array[SettingsManager])


## Enum for ColumnDisplay
enum ColumnDisplay {
	ALL,			## Displays all SettignModules, sorted by catigory
	PRIMARY			## Displays all SettingModules with the primary flag
}


## List of Data.Types that should not be displayed in the table
const DISALLOWED_DATA_TYPES: Array[Data.Type] = [
	Data.Type.NULL, 
	Data.Type.ACTION,
	Data.Type.PACKEDSCENE
]


## The Table2 node used to display SettingsModules
@onready var _table: Table2 = %Table


## RefMap for SettignsManager: Table2.Row
var _managers: RefMap = RefMap.new()

## Stores all Table2.Columns using { class_index: { SettingsModule.get_id(): Table2.Column } }
var _columns: Dictionary[int, Dictionary]

## Stores all users of each column in a set, so they can be deleted when not used
## { Table.Column: { SettingsManager: SettingsModule } }
var _column_users: Dictionary[Table2.Column, Dictionary]

## Curent ColumnDisplay mode
var _column_display: ColumnDisplay = ColumnDisplay.PRIMARY


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("SettingsManagerTableView")


## Clears and removed all SettingsManagers in this table
func clear() -> void:
	_managers.clear()
	_columns.clear()
	_table.clear()
	_column_users.clear()


## Adds a manager to the table
func add_manager(p_manager: SettingsManager) -> void:
	if has_manager(p_manager):
		return
	
	var inhr_list: Dictionary[String, int]
	var data_to_add: Dictionary[Table2.Column, Variant]
	
	for classname: String in p_manager.get_inheritance_list():
		inhr_list[classname] = inhr_list.size() + 1
	
	for module: SettingsModule in p_manager.get_modules().values():
		if not is_module_allowed(module):
			continue
		
		var index: int = inhr_list[module.get_visual_category()]
		var id: String = module.get_id() 
		var column: Table2.Column = _columns.get(index, {}).get(id)
		
		if not is_instance_valid(column):
			column = _table.create_column().set_title(id).set_visable(is_module_visable(module))
			_columns.get_or_add(index, {})[id] = column
		
		data_to_add[column] = module
		_column_users.get_or_add(column, {})[p_manager] = module
		
		if is_module_visable(module):
			column.set_visable(true)
		
		if not _table.get_sort_column() and p_manager.get_sort_module() == module:
			_table.set_sort_column(column)
	
	_managers.map(p_manager, _table.create_row().load_data(data_to_add))
	queue(_update_visable_columns)


## Removes a manager from the table
func remove_manager(p_manager: SettingsManager) -> void:
	if not has_manager(p_manager):
		return
	
	_table.remove_row(_managers.left(p_manager))
	_managers.erase_left(p_manager)
	
	for column: Table2.Column in _column_users.keys():
		var user_dict: Dictionary = _column_users[column]
		user_dict.erase(p_manager)
		
		if not user_dict.size():
			_table.remove_column(column)
	
	queue(_update_visable_columns)


## Selects the given SettingsManagers
func select_managers(p_managers: Array) -> void:
	for manager: Variant in p_managers:
		if not manager is SettingsManager:
			continue
		
		pass


## Sets the ColumnDisplay mode
func set_column_display(p_column_display: ColumnDisplay) -> void:
	_column_display = p_column_display
	_update_visable_columns()


## Returns all selected SettingsManagers
func get_selected_managers() -> Array[SettingsManager]:
	var result: Array[SettingsManager]
	
	for row: Table2.Row in _table.get_selected_rows():
		result.append(_managers.right(row))
	
	return result


## Returns the current first selected SettingsManager, or null
func get_selected_manager() -> SettingsManager:
	var first: Table2.Cell = _table.get_first_selected()
	
	if is_instance_valid(first):
		return _managers.right(first.get_row(), null)
	else:
		return null


## Returns all SettingsManagers in this table
func get_managers() -> Array[SettingsManager]:
	var result: Array[SettingsManager]
	
	result.assign(_managers.get_left())
	return result


## Returns the ColumnDisplay mode
func get_column_display() -> ColumnDisplay:
	return _column_display


## Returns true if the given SettingsManager is present in this table
func has_manager(p_manager: SettingsManager) -> bool:
	return _managers.has_left(p_manager)


## Returns true if any SettingsManagers are seleced
func is_any_selected() -> bool:
	return _table.is_any_selected()


## Returns true if the given SettingsModule is allowed to be displayed
func is_module_allowed(p_module: SettingsModule) -> bool:
	if p_module.get_data_type() in DISALLOWED_DATA_TYPES:
		return false
	
	return true


## Returns true if this module should be visable
func is_module_visable(p_module: SettingsModule) -> bool:
	if not is_instance_valid(p_module):
		return false
	
	match _column_display:
		ColumnDisplay.ALL:
			return true
		ColumnDisplay.PRIMARY:
			return p_module.is_primary()
		_:
			return false


## Updates the visable colulms using current ColumnDisplay
func _update_visable_columns() -> void:
	for column: Table2.Column in _column_users:
		for module: SettingsModule in _column_users[column].values():
			var visable: bool = false
			
			if is_module_visable(module):
				visable = true
			
			column.set_visable(visable)


## Called when the selection on the Table2 node is changed
func _on_table_selection_changed() -> void:
	var selected_managers: Array[SettingsManager]
	
	for row: Table2.Row in _table.get_selected_rows():
		selected_managers.append(_managers.right(row))
	
	selection_changed.emit(selected_managers)
