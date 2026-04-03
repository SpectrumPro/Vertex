# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name PanelMenuBar extends UIComponent
## PanelMenuBar Component


## The UIPanelEditControls
@onready var _edit_controls: UIPanelEditControls = %EditControls

## The ComponentButton
@onready var _component_button: ComponentButton = %ComponentButton


## Popup style state
var _popup_style: bool = false

## The owner of this Menubar
var _owner: UIPanel


## Returns the UIPanelEditControls
func get_edit_controls() -> UIPanelEditControls:
	return _edit_controls


## Returns the ComponentButton
func get_component_button() -> ComponentButton:
	return _component_button


## Gets the owner
func get_panel_owner() -> UIPanel:
	return _owner


## Sets the popup style state
func set_popup_style(p_popup_style: bool) -> bool:
	if p_popup_style == _popup_style:
		return false
	
	_popup_style = p_popup_style
	add_theme_stylebox_override("panel", ThemeManager.StyleBoxes.PanelMenuBarPopup if _popup_style else ThemeManager.StyleBoxes.PanelMenuBarBase)
	
	return true


## Sets the owner UIPanel
func _set_panel_owner(p_owner: UIPanel) -> void:
	_owner = p_owner
