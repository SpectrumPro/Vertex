# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name CorePopups extends CoreGlobal
## Collection of shortcuts for opening UIPopups


## init 
func _init(p_uuid: String = "", ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("CorePopups")


## Prompts the user to select a UIPanel
func PanelSelector(p_source: Node) -> Promise:
	return Interface.show_window_popup(UIPanelSelector, p_source, null)


## Promps the user with UIPaneSettings
func PanelSettings(p_source: Node, p_panel: UIPanel) -> Promise:
	return Interface.show_window_popup(UIPanelSettings, p_source, p_panel)


## Promps the user with UIPaneSettings
func ObjectSelector(p_source: Node, p_gbc_class: Variant, p_class_filter: Variant = "") -> Promise:
	var object_picker: UIObjectSelector = Interface.get_window_popup(UIObjectSelector, p_source)
	object_picker.select_mode_object(p_gbc_class, p_class_filter)
	
	return Interface.show_window_popup(UIObjectSelector, p_source, null)


## Promps the user with UIPaneSettings
func ObjectSelector_gbc_index(p_source: Node) -> Promise:
	var object_picker: UIObjectSelector = Interface.get_window_popup(UIObjectSelector, p_source)
	object_picker.select_mode_gbc_index()
	
	return Interface.show_window_popup(UIObjectSelector, p_source, null)


## Promps the user with UIPaneSettings
func ObjectSelector_gbc_object(p_source: Node) -> Promise:
	var object_picker: UIObjectSelector = Interface.get_window_popup(UIObjectSelector, p_source)
	object_picker.select_mode_gbc_object()
	
	return Interface.show_window_popup(UIObjectSelector, p_source, null)


## Promps the user with UIPaneSettings
func ObjectSelector_gbc_class(p_source: Node) -> Promise:
	var object_picker: UIObjectSelector = Interface.get_window_popup(UIObjectSelector, p_source)
	object_picker.select_mode_gbc_class()
	
	return Interface.show_window_popup(UIObjectSelector, p_source, null)


## Promps the user with UIObjectPicker
func ObjectSelector_class(p_source: Node, p_gbc_class: Variant, p_class_filter: Variant = "") -> Promise:
	var object_picker: UIObjectSelector = Interface.get_window_popup(UIObjectSelector, p_source)
	object_picker.select_mode_class(p_gbc_class, p_class_filter)
	
	return Interface.show_window_popup(UIObjectSelector, p_source, null)


## Prompts the user with UIInterfaceSelector
func NetworkSelector(p_source: Node) -> Promise:
	var promise: Promise = Interface.show_window_popup(UINetworkSelector, p_source, null)
	
	return promise


## Creates and adds a blank UIPopupDialog
func PopupDialog(p_source: Node, p_title: String = "") -> UIPopupDialog:
	return Interface.create_popup_dialog(p_source, p_title)


## Prompts the user with UIChildManager
func UChildManager(p_source: Node, p_manager: ChildManager) -> Promise:
	return Interface.show_window_popup(UIChildManager, p_source, p_manager)


## Prompts the user with UISettingsManager
func USettingsManager(p_source: Node, p_manager: SettingsManager) -> void:
	Interface.show_window_popup(UISettingsManager, p_source, p_manager)


## Promps the user with SettingsModule, accepts either a SettingsModule or Array[SettingsModule]
func USettingsModule(p_source: Node, p_modules: Variant) -> Promise:
	var modules: Array[SettingsModule]
	
	match typeof(p_modules):
		TYPE_ARRAY:
			modules.assign(p_modules)
		TYPE_OBJECT when p_modules is SettingsModule:
			modules.append(p_modules)
	
	return Interface.show_window_popup(UIPopupSettingsModule, p_source, modules)


## Promps the user with a DataInput
func show_data_input(p_source: Node, p_data_type: Data.Type, p_default: Variant, p_label: String) -> Promise:
	var promise: Promise = Interface.show_window_popup(UIPopupSettingsModule, p_source, [])
	var module_view: UIPopupSettingsModule = promise.get_object_refernce()
	var dummy_module: SettingsModule = SettingsModule.new(p_label, p_label, p_data_type, SettingsModule.Type.SETTING, promise.resolvev, func (): return p_default, [], p_source)
	
	module_view.set_module([dummy_module])
	module_view.focus()
	return promise


## Prompts the user with a delete confirmation dialog
func show_delete_confirmation(p_source: Node, p_title: String = "Confirm Deletion?") -> Promise:
	return PopupDialog(p_source, p_title).preset(UIPopupDialog.Preset.DELETE, p_title).promise()


## Prompts the user to delete the given engine components
func confirm_delete_components(p_source: Node, p_components: Array, p_auto_delete: bool = true) -> Promise:
	var title: PackedStringArray
	title.append("Delete")
	
	if p_components.size() > 1:
		title.append(": " + str(p_components.size()) + " Components?")
	elif p_components.size() and Data.is_gbc_complient(p_components[0]):
		title.append(" Selected " + p_components[0].get_class_name() + "?")
	else:
		return
	
	return PopupDialog(p_source, "").preset(UIPopupDialog.Preset.DELETE, "".join(title)).promise().then(func ():
		if not p_auto_delete:
			return
		
		for component: Variant in p_components:
			if not Data.is_gbc_complient(component):
				continue
			
			component.delete_rpc()
	)


## Prompts the user with a custom panel popup
func create_panel_popup(p_source: Node, p_panel_class: Variant) -> UIPanel:
	return Interface.create_panel_popup(p_source, p_panel_class)
