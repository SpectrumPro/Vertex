# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SettingsManagerModuleView extends PanelContainer


## Title label
@onready var _title: Label = %Title

## ExpandHide button
@onready var _expand_hide_button: Button = %ExpandHide

## SettingsContainer VBox
@onready var _settings_container: VBoxContainer = %SettingContainer

## The PanelContainer containing ChildButtonContainer
@onready var _child_button_panel: PanelContainer = %ChildButtonPanel

## The BoxContainer containing ChildManager open buttons
@onready var _child_button_container: BoxContainer = %ChildButtonContainer


## Disables this settings module
func set_disabled(state: bool) -> void:
	_on_expand_hide_toggled(state)
	_expand_hide_button.disabled = state


## Sets the title
func set_title(title: String) -> void:
	_title.text = title


## Shows a setting
func show_module(p_module: SettingsModule) -> void:
	var data_input: DataInput = UIDB.instance_data_input(p_module.get_data_type(), p_module.get_sub_type())
	
	if data_input is not DataInputNull:
		data_input.ready.connect(func ():
			data_input.set_module(p_module)
			data_input.set_show_label(true)
			data_input.set_label_text(p_module.get_name())
		, CONNECT_ONE_SHOT)
	
	_settings_container.add_child(data_input)


## Adds a button to open the given ChildManager
func show_child_manager(p_manager: ChildManager, p_id: String) -> void:
	var button: Button = Button.new()
	
	button.set_text(p_id)
	button.set_button_icon(preload("res://modules/Vertex/assets/icons/OpenInNew.svg"))
	button.set_icon_alignment(HORIZONTAL_ALIGNMENT_LEFT)
	button.set_flat(true)
	
	button.pressed.connect(Popups.UChildManager.bind(self, p_manager))
	
	_child_button_container.add_child(button)
	_child_button_panel.show()


## Called when the ExpandHide button is toggled
func _on_expand_hide_toggled(toggled_on: bool) -> void:
	_settings_container.visible = not toggled_on
	_expand_hide_button.icon = preload("res://modules/Vertex/assets/icons/UnfoldMore.svg") if toggled_on else preload("res://modules/Vertex/assets/icons/UnfoldLess.svg") 
