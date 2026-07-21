# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name DataInputFloat extends DataInput
## DataInput for Data.Type.FLOAT


## The LineEdit
var _line_edit: LineEdit


## Ready
func _ready() -> void:
	_data_type = Data.Type.FLOAT
	_line_edit = $HBox/LineEdit
	_line_edit.text_changed.connect(func (_p_text): _make_unsaved())
	_label = $HBox/Label
	_outline = $HBox/LineEdit/Outline
	_quantity_button = %Quantity
	_focus_node = _line_edit


## Called when the orignal value is changed
func _module_value_changed(p_value: Variant, ..._p_args) -> void:
	if p_value is float and not _unsaved:
		_line_edit.set_text(_module.get_value_string())


## Resets this DataInputString
func _reset() -> void:
	_line_edit.clear()


## Called when the editable state is changed
func _set_editable(p_editable: bool) -> void:
	_line_edit.set_editable(p_editable)


## Called when the text is submitted in the LineEdit
func _on_line_edit_text_submitted(new_text: String) -> void:
	set_value(Data.autofill_entrys(new_text, _modules.size(), TYPE_FLOAT, true, _module.get_min(), _module.get_max()))
