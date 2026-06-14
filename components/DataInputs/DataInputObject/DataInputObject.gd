# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputObject extends DataInput
## DataInput for Data.Type.OBJECT


## The LineEdit
var _button: Button

## The current EngineComponent
var _current_component: Object

## SignalGroup for Object
var _component_connections: SignalGroup = SignalGroup.new([
	_on_component_name_changed
]).set_prefix("_on_component_")


## Ready
func _ready() -> void:
	_data_type = Data.Type.OBJECT
	_button = $HBox/Button
	_label = $HBox/Label
	_outline = $HBox/Button/Outline
	_focus_node = _button


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ...p_args) -> void:
	_component_connections.disconnect_object(_current_component)
	_current_component = p_value
	_component_connections.connect_object(_current_component)
	
	if is_instance_valid(_current_component):
		_button.set_text(_current_component.get_uname())
		_button.add_theme_color_override("font_color", ThemeManager.Colors.FontColor)
	else:
		_button.set_text("null")
		_button.add_theme_color_override("font_color", ThemeManager.Colors.FontDisabledColor)


## Resets this DataInputString
func _reset() -> void:
	_module_value_changed(null)


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_button.set_disabled(not p_editable)


## Called when the component name is changed
func _on_component_name_changed(p_name: String) -> void:
	_button.set_text(p_name)


## Called when the button is pressed
func _on_button_pressed() -> void:
	Popups.ObjectSelector(self, _module.get_base_class(), _module.get_class_filter()).then(func (p_component: Object):
		set_value([[p_component]])
	)
