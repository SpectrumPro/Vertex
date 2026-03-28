# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CoreUIDB extends Node
## Contains a list of all the UIPanel classes


## File path for all UIPanels
const UI_PANEL_LOCATION: String = "res://panels/"

## File path for all UIPanels
const UI_POPUP_LOCATION: String = "res://panels/popups/"

## File path for all UIComponents
const UI_COMPONENT_LOCATION: String = "res://components/"

## File path for all UIPanels
const DATA_INPUT_LOCATION: String = "res://components/DataInputs/"

## File path for all UIPanels
const ICON_LOCATION: String = "res://assets/icons/"


## All UIPanels
var _panels: Dictionary[String, PackedScene] = {
	"UIWindowManager":		load(_p("UIWindowManager")),
	"UISettingsManager":	load(_p("UISettingsManager")),
	"UIPanelSettings":		load(_p("UIPanelSettings")),
}


## All UIPopups
var _popups: Dictionary[String, PackedScene] = {
	"UICommandPalette": 		load(_u("UICommandPalette")),
	"UINetworkSelector": 		load(_u("UINetworkSelector")),
	"UIObjectSelector": 		load(_u("UIObjectSelector")),
	"UIPanelSelector": 			load(_u("UIPanelSelector")),
	"UIPopupDialog": 			load(_u("UIPopupDialog")),
	"UIPopupSettingsModule": 	load(_u("UIPopupSettingsModule")),
	"UIWindowID": 				load(_u("UIWindowID")),
}


## All UIComponents
var _components: Dictionary[String, PackedScene] = {
	"ComponentButton":			load(_c("ComponentButton")),
	"SearchableClassTree":				load(_c("SearchableClassTree")),
	"SelectBox":				load(_c("SelectBox")),
	"SettingsManagerMultiView":	load(_c("SettingsManagerMultiView")),
	"SettingsManagerView":		load(_c("SettingsManagerView")),
	"StartUpNoticeContainer":	load(_c("StartUpNoticeContainer")),
	"Table":					load(_c("Table")),
}


## All DataInputs by DataType
var _data_inputs: Dictionary[Data.Type, Variant] = {
	Data.Type.NULL:				load(_d("DataInputNull")),
	Data.Type.STRING:			load(_d("DataInputString")),
	Data.Type.BOOL:				load(_d("DataInputBool")),
	Data.Type.INT:				load(_d("DataInputInt")),
	Data.Type.FLOAT:			load(_d("DataInputFloat")),
	Data.Type.VECTOR2:			load(_d("DataInputVector2")),
	Data.Type.VECTOR2I:			load(_d("DataInputVector2")),
	Data.Type.COLOR:			load(_d("DataInputColor")),
	Data.Type.ENUM:				load(_d("DataInputEnum")),
	Data.Type.BITFLAGS:			load(_d("DataInputBitFlags")),
	Data.Type.IP:				load(_d("DataInputIPAddr")),
	Data.Type.SETTINGSMANAGER:	load(_d("DataInputSettingsManager")),
	Data.Type.ACTION:			load(_d("DataInputAction")),
}


## All UIPanels sorted by category
var _panels_by_category: Dictionary[String, Array] = {
	"System": [
		"UIWindowManager",
	],
}


## All class icons
var _class_icons: Dictionary[String, Texture2D] = {
	"_": 					load(_i("Component")),
	"null":					load(_i("Reset")),
	"Interface": 			load(_i("Panel")),
	"ClientInterface": 		load(_i("Panel")),
}


## init
func _init() -> void:
	Config.load_config("res://UIDBConfig.gd")
	
	_panels.merge(Config.panels, true)
	_popups.merge(Config.popups, true)
	
	_components.merge(Config.components, true)
	_class_icons.merge(Config.class_icons, true)
	
	Utils.merge_deep(_data_inputs, Config.data_inputs)
	Utils.merge_deep(_panels_by_category, Config.panels_by_category)


## Returns the file path of a UIPanel
static func _p(p_panel_class: String) -> String:
	return str(UI_PANEL_LOCATION, p_panel_class, "/", p_panel_class, ".tscn")


## Returns the file path of a UIPopup
static func _u(p_popup_class: String) -> String:
	return str(UI_POPUP_LOCATION, p_popup_class, "/", p_popup_class, ".tscn")


## Returns the file path of a UIComponent
static func _c(p_component_class: String) -> String:
	return str(UI_COMPONENT_LOCATION, p_component_class, "/", p_component_class, ".tscn")


## Returns the file path of a DataInput
static func _d(p_data_input_class: String) -> String:
	return str(DATA_INPUT_LOCATION, p_data_input_class, "/", p_data_input_class, ".tscn")


## Returns the file path of a Icon
static func _i(p_data_input_class: String) -> String:
	return str(ICON_LOCATION, p_data_input_class, ".svg")


## Returns the PackedScene for a UIPanel
func get_panel_scene(p_panel_class: String) -> PackedScene:
	return _panels.get(p_panel_class, null)


## Returns the PackedScene for a UIPopup
func get_popup_scene(p_popup_class: String) -> PackedScene:
	return _popups.get(p_popup_class, null)


## Returns the PackedScene for a UIComponent
func get_component_scene(p_component_class: String) -> PackedScene:
	return _components.get(p_component_class, null)


## Returns the PackedScene for a DataInput
func get_data_input_scene(p_data_type: Data.Type) -> PackedScene:
	return _data_inputs.get(p_data_type, null)


## Creates a new instance of a UIPanel
func instance_panel(p_panel_class: Variant) -> UIPanel:
	if p_panel_class is Script:
		p_panel_class = String((p_panel_class as Script).get_global_name())
	
	if p_panel_class is not String or not has_panel(p_panel_class):
		return null
	
	return _panels[p_panel_class].instantiate()


## Creates a new instance of a UIPopup
func instance_popup(p_popup_class: Variant) -> UIPopup:
	if p_popup_class is Script:
		p_popup_class = String((p_popup_class as Script).get_global_name())
	
	if p_popup_class is not String or not has_popup(p_popup_class):
		return null
	
	return _popups[p_popup_class].instantiate()


## Creates a new instance of a UIComponent
func instance_component(p_component_class: Variant) -> UIComponent:
	if p_component_class is Script:
		p_component_class = String((p_component_class as Script).get_global_name())
	
	if p_component_class is not String or not has_component(p_component_class):
		return null
	
	return _components[p_component_class].instantiate()


## Creates a new instance of a panel
func instance_data_input(p_data_type: Data.Type, p_sub_type: int = Data.Sub.Type.NULL) -> DataInput:
	if has_data_input(p_data_type):
		var entry: Variant = _data_inputs[p_data_type]
		
		if entry is PackedScene:
			return entry.instantiate()
		
		elif entry is Dictionary and entry.has(p_sub_type): 
			return entry[p_sub_type].instantiate()
	
	var null_type: DataInputNull = _data_inputs[Data.Type.NULL].instantiate()
	
	null_type.ready.connect(func ():
		null_type.set_unsupported_type(p_data_type)
	)
	
	return null_type


## Checks if a UIPanel exists
func has_panel(p_panel_class: String) -> bool:
	return _panels.has(p_panel_class)


## Checks if a UIPopup exists
func has_popup(p_popup_class: String) -> bool:
	return _popups.has(p_popup_class)


## Checks if a UIComponent exists
func has_component(p_component_class: String) -> bool:
	return _components.has(p_component_class)


## Checks if a DataInput exists
func has_data_input(p_data_type: Data.Type) -> bool:
	return _data_inputs.has(p_data_type)


## Gets all the panel categories
func get_panel_categories() -> Array:
	return _panels_by_category.keys()


## Gets all the panels in the given category
func get_panels_in_category(p_category: String) -> Array:
	return _panels_by_category.get(p_category, [])


## Gets an icon for the given classname
func get_class_icon(p_classname: Variant) -> Texture2D:
	if p_classname is Script:
		p_classname = String((p_classname as Script).get_global_name())
	
	return _class_icons.get(p_classname, _class_icons["_"])


## Stores configs
class Config:
	## All user defined UIPanels
	static var panels: Dictionary
	
	## All user defined UIPanels
	static var popups: Dictionary
	
	## All user defined UIPanels
	static var components: Dictionary
	
	## All user defined UIPanels
	static var data_inputs: Dictionary
	
	## All user defined UIPanels
	static var class_icons: Dictionary
	
	## Categorys of the user defined panels
	static var panels_by_category: Dictionary
	
	
	## Loads config from a file
	static func load_config(p_path: String) -> bool:
		var script: Variant = load(p_path)
		
		if script is not GDScript or script.get("config") is not Dictionary:
			return false
		
		var config: Dictionary = script.get("config")
		
		panels = type_convert(config.get("panels", panels), TYPE_DICTIONARY)
		popups = type_convert(config.get("popups", popups), TYPE_DICTIONARY)
		
		components = type_convert(config.get("components", components), TYPE_DICTIONARY)
		data_inputs = type_convert(config.get("data_inputs", data_inputs), TYPE_DICTIONARY)
		
		class_icons = type_convert(config.get("class_icons", class_icons), TYPE_DICTIONARY)
		panels_by_category = type_convert(config.get("panels_by_category", panels_by_category), TYPE_DICTIONARY)
		
		return true
