# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SettingsManagerMultiView extends UIComponent
## SettingsManagerMultiView


## Emitted when a SettingsManager is selected
signal manager_selected(manager: SettingsManager)


## The Table
@onready var _table: Table = %Table

## The SettingsManagerView
@onready var _settings_manager_view: SettingsManagerView = %SettingsManagerView


## Defines what SettingsModule entrys to show in the Table
var _column_entrys: Array[String] = ["name"]

## True if icons should be auto added based on an object type
var _display_icons: bool = false

## RefMap for Table.Column: String
var _table_columns: RefMap = RefMap.new()

## RefMap for Table.Row: SettingsManager
var _manager_rows: RefMap = RefMap.new()

## The current selected manager
var _selected_manager: SettingsManager


## Init
func _init() -> void:
	super._init()
	
	_set_class_name("SettingsManagerMultiView")


## Ready
func _ready() -> void:
	reset()


## Adds a manager
func add_manager(p_manager: SettingsManager) -> void:
	if _manager_rows.has_right(p_manager):
		return
	
	var rows: Dictionary[int, Variant]
	var icon: Texture2D
	
	for column_name: String in _table_columns.get_right():
		if not p_manager.get_entry(column_name):
			continue
		
		var entry: SettingsModule = p_manager.get_entry(column_name)
		var column: Table.Column = _table_columns.right(column_name)
		
		if entry.get_data_type() == column.get_data_type():
			rows[column.get_id()] = entry
		elif column.get_data_type() == Data.Type.NULL:
			column.set_data_type(entry.get_data_type())
			rows[column.get_id()] = entry
	
	if _display_icons:
		icon = UIDB.get_class_icon(p_manager.get_inheritance_child())
	
	_manager_rows.map(_table.add_row(rows, icon), p_manager)


## Removes a manager
func remove_manager(p_manager: SettingsManager) -> void:
	if not _manager_rows.has_right(p_manager):
		return
	
	if _table.get_selected_row() == _manager_rows.right(p_manager):
		_settings_manager_view.reset()
	
	_table.remove_row(_manager_rows.right(p_manager))
	_manager_rows.erase_right(p_manager)


## Selects a manager
func select_manager(p_manager: SettingsManager) -> void:
	if not _manager_rows.has_right(p_manager):
		return
	
	_manager_rows.right(p_manager).select()


## Resets 
func reset() -> void:
	_table_columns.clear()
	_manager_rows.clear()
	_selected_manager = null
	
	_table.clear()
	_table.clear_columns()
	_settings_manager_view.reset()
	
	for column_name: String in _column_entrys:
		_table_columns.map(_table.add_column(column_name.capitalize(), Data.Type.NULL), column_name)


## Returns the display icons state
func get_display_icons() -> bool:
	return _display_icons


## Returns the SettingsModule entry IDs to show in the table
func get_column_entrys() -> Array[String]:
	return _column_entrys.duplicate()


## Gets the current selected SettingsManager
func get_selected_manager() -> SettingsManager:
	return _selected_manager


## Gets the owner of the selected SettingsManager, or null
func get_selected_owner() -> Object:
	var selected_manager: SettingsManager = get_selected_manager()
	
	if is_instance_valid(selected_manager):
		return selected_manager.get_owner()
	else:
		return null


## Sets the display icons state. a full reset() is needed to update already visable rows
func set_display_icons(p_display_icons: bool) -> void:
	_display_icons = p_display_icons


## Sets the SettingsModule entry IDs to show in the table, a full reset() is needed to reload the rows
func set_column_entrys(p_entrys: Array[String]) -> void:
	_column_entrys = p_entrys.duplicate()


## Returns true if there is a selected SettingsManager
func is_any_selected() -> bool:
	return is_instance_valid(_selected_manager)


## Called when the selection is changed on the table
func _on_table_selection_changed() -> void:
	if _table.is_any_selected():
		_selected_manager = _manager_rows.left(_table.get_selected_row())
		
		_settings_manager_view.set_manager(_selected_manager)
		manager_selected.emit(_selected_manager)
	
	else:
		_selected_manager = null
		_settings_manager_view.reset()
		manager_selected.emit(null)
