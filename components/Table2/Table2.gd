# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name Table2 extends UIComponent
## Renders a Table with Rows, Columns, and Cells


## Emitted when the current selection is changed
signal selection_changed()

## Emitted when an edit is requested on cells that do not contain a SettingsModule
signal edit_requested(cells: Array[Cell])


## Default Column width
const COLUMN_WIDTH: int = 100

## Default row height
const ROW_HEIGHT: int = 40

## Cell hover bg color
const CELL_HOVER_COLOR: Color = Color(0.458, 0.458, 0.458, 0.353)

## Row hilight color
const ROW_HILIGHT_COLOR: Color = Color("0f7af53a")

## Cell select color
const CELL_SELECT_COLOR: Color = Color("0f7af5c2")

## Amount to lighten the text of cells when they are selected
const CELL_TEXT_SELECTED_LIGHTEN: float = 1


## Enum for SortDirection
enum SortDirection {
	ASCENDING,		## Sort A-Z
	DESCENDING		## Sort Z-A
}


## The HScrollBar
@onready var _h_scroll_bar: HScrollBar = %HScrollBar

## The VScrollBar
@onready var _v_scroll_bar: VScrollBar = %VScrollBar

## The CanvasItem to draw on
@onready var _canvas: Control = %Canvas

## The SelectBox
@onready var _select_box: SelectBox = %SelectBox


## Stores all rows
var _rows: Array[Row]

## Stores all column
var _columns: Array[Column]

## Current cached size of the table
var _size_cache: Vector2 = Vector2.ZERO

## Set for storing current selection
var _selection: Set = Set.new(TYPE_OBJECT)

## The cell currently being hovered
var _hovered_cell: Cell

## Current SortDirection
var _sort_direction: SortDirection = SortDirection.ASCENDING

## The Column used to sort the table by
var _sort_column: Column

## The font used in all text
var _font: Font

## Font size in pixels
var _font_size: int

## Margin to add when rendering font from bottom left cornor 
var _text_margin: Vector2 = Vector2(5, -1)


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	_set_class_name("Table2")


## ready
func _ready() -> void:
	_font = ThemeDB.fallback_font
	_font_size = ThemeDB.fallback_font_size
	
	_canvas.resized.connect(_on_canvas_resized)
	_canvas.gui_input.connect(_on_canvas_gui_input)
	_canvas.mouse_exited.connect(_on_canvas_mouse_exited)
	_canvas.draw.connect(_draw_table)


## draw
func _draw_table() -> void:
	var scroll: Vector2 = _get_scroll_offset()
	
	for row: Row in _rows:
		if row.get_position() > _canvas.size.y - scroll.y:
			break
		
		if row.get_position() + row.get_height() + scroll.y < 0:
			continue
		
		row._draw(_canvas, scroll)
	
	for column: Column in _columns:
		if column.get_position() > _canvas.size.x - scroll.x:
			break
		
		if column.get_position() + column.get_width() + scroll.x < 0:
			continue
		
		column._draw(_canvas, scroll)


## Creates and returns a new Row 
func create_row() -> Row:
	var new_row: Row = Row.new(self, _rows.size(), ROW_HEIGHT, _size_cache.y)
	
	_size_cache.y += new_row.get_height()
	queue_redraw_table()
	
	_rows.append(new_row)
	return new_row


## Creates and return a new Column
func create_column() -> Column:
	var new_column: Column = Column.new(self, _columns.size(), COLUMN_WIDTH, _size_cache.x)
	
	_size_cache.x += new_column.get_width()
	queue_redraw_table()
	
	_columns.append(new_column)
	return new_column


## Removes the given row, frees from memory
func remove_row(p_row: Row) -> void:
	if p_row.get_table() != self:
		return
	
	_rows.erase(p_row)
	p_row._delete()
	
	queue(_recompute_rows)
	queue_redraw_table()


## Removes the given column, frees from memory
func remove_column(p_column: Column) -> void:
	if p_column.get_table() != self:
		return
	
	_columns.erase(p_column)
	p_column._delete()
	
	if _sort_column == p_column:
		set_sort_column(null)
	
	queue(_recompute_columns)
	queue_redraw_table()


## Clears all rows and columns in the table
func clear() -> void:
	clear_data()
	
	for column: Column in _columns:
		remove_column(column)


## Clears all rows, keeping columns
func clear_data() -> void:
	for row: Row in _rows:
		remove_row(row)


## Sorts the rows in the table based on cells in the given column
func sort_table(p_column: Column = _sort_column, p_direction: SortDirection = _sort_direction) -> void:
	if not is_instance_valid(_sort_column) or _sort_column.get_table() != self:
		return
	
	var row_values: Array[Array]
	
	for row: Row in _rows:
		row_values.append([
			row,
			row.get_cell_at_column(_sort_column).get_value()
		])
	
	row_values.sort_custom(func(a: Array, b: Array): 
		var a_value: Variant = a[1]
		var b_value: Variant = b[1]
		
		match _sort_direction:
			SortDirection.ASCENDING:
				return a_value.naturalnocasecmp_to(b_value) < 0
			SortDirection.DESCENDING:
				return a_value.naturalnocasecmp_to(b_value) > 0
	)
	
	for index: int in range(row_values.size()):
		row_values[index][0].set_index(index)


## Deselects all cells in the table
func deselect_all() -> void:
	for cell: Cell in _selection.get_as_array():
		cell._set_selected(false)
	
	_selection.clear()
	
	queue(_emit_selection)
	queue_redraw_table()


## Edits the selected cells, in the selection order
func edit_selected() -> void:
	if not _selection.size():
		return
	
	var selection: Array = _selection.get_as_array()
	var first: Cell = selection[0]
	var is_settings_module: bool = first.is_using_settings_module()
	
	filter_selection(
		null, 
		first.get_settings_module().get_data_type() if is_settings_module else Data.Type.NULL
	)
	
	if is_settings_module:
		Popups.USettingsModule(self, _selection.get_as_array().map(func (p_cell: Cell):
			return p_cell.get_settings_module()
		))
	else:
		var cells: Array[Cell]
		
		cells.assign(_selection.get_as_array())
		edit_requested.emit(cells)


## Updates and filters the selection to match the given inputs.
## p_data_type is used to filter SettingsModules. 
func filter_selection(p_column: Column, p_data_type: Data.Type = Data.Type.NULL) -> void:
	for cell: Cell in _selection.get_as_array():
		if is_instance_valid(p_column) and p_column != cell.get_column():
			cell.set_selected(false)
		
		if p_data_type not in [Data.Type.NULL, Data.Type.ANY] \
		and cell.is_using_settings_module() \
		and cell.get_settings_module().get_data_type() != p_data_type:
			cell.set_selected(false)


## Queues a table sort with the current sort settings
func queue_sort() -> void:
	queue(sort_table)


## Queues a redraw of the table
func queue_redraw_table() -> void:
	_canvas.queue_redraw()


## Sets the index of the given row
func set_row_index(p_row: Row, p_index: int) -> void:
	if p_row.get_table() != self:
		return
	
	if p_row.get_index() == p_index or p_index < 0 or p_index >= _rows.size():
		return
	
	_rows.remove_at(p_row.get_index())
	_rows.insert(p_index, p_row)
	
	_recompute_rows()
	queue_redraw_table()


## Sets the height in pixels of the given row
func set_row_height(p_row: Row, p_height: int) -> void:
	if p_row.get_table() != self:
		return
	
	if p_height < 0:
		return
	
	p_row._set_height(p_height)
	
	_recompute_rows()
	queue_redraw_table()


## Sets the index of the given Column
func set_column_index(p_column: Column, p_index: int) -> void:
	if p_column.get_table() != self:
		return
	
	if p_column.get_index() == p_index or p_index < 0 or p_index >= _columns.size():
		return
	
	_columns.remove_at(p_column.get_index())
	_columns.insert(p_index, p_column)
	
	_recompute_columns()
	queue_redraw_table()


## Sets the width in pixels of the given column
func set_column_width(p_column: Column, p_width: int) -> void:
	if p_column.get_table() != self:
		return
	
	if p_width < 0:
		return
	
	p_column._set_width(p_width)
	
	_recompute_columns()
	queue_redraw_table()


## Sets the selected state of the given cell
func set_cell_selected(p_cell: Cell, p_selected: bool) -> void:
	if p_cell.get_table() != self:
		return
	
	p_cell._set_selected(p_selected)
	_selection.remove(p_cell)
	
	if p_selected:
		_selection.add(p_cell)
	
	queue(_emit_selection)
	queue_redraw_table()


## Sets the column to sort the table by
func set_sort_column(p_column: Column) -> void:
	if not is_instance_valid(p_column):
		_sort_column = null
		return
	
	if p_column.get_table() != self:
		return
	
	_sort_column = p_column
	queue_sort()


## Sets the direction to sort the table by
func set_sort_direction(p_direction: SortDirection) -> void:
	_sort_direction = p_direction
	queue_sort()


## Returns the row at the given index, or null
func get_row(p_index: int) -> Row:
	if p_index < 0 or p_index >= _rows.size():
		return null
	
	return _rows[p_index]


## Returns the column at the given index or null
func get_column(p_index: int) -> Column:
	if p_index < 0 or p_index >= _columns.size():
		return null
	
	return _columns[p_index]


## Returns all selected Cells in selection order
func get_selected() -> Array[Cell]:
	var selected: Array[Cell]
	
	selected.assign(_selection.get_as_array())
	return selected


## Returns all selected rows
func get_selected_rows() -> Array[Row]:
	var selected: Set = Set.new(TYPE_OBJECT)
	var result: Array[Row]
	
	for cell: Cell in _selection.get_as_array():
		selected.add(cell)
	
	result.assign(selected.get_as_array())
	return result


## Returns the first selected item
func get_first_selected() -> Cell:
	var selected: Array = _selection.get_as_array()
	
	if selected.size():
		return selected[0]
	else:
		return null


## Returns the last selected item
func get_last_selected() -> Cell:
	var selected: Array = _selection.get_as_array()
	
	if selected.size():
		return selected[-1]
	else:
		return null


## Returns the size of the selection
func get_selection_size() -> int:
	return _selection.size()


## Returns the sort column
func get_sort_column() -> Column:
	return _sort_column


## Returns the sort direction
func get_sort_direction() -> SortDirection:
	return _sort_direction


## Returns the font used by this table
func get_font() -> Font:
	return _font


## Returns the font sized used by this table
func get_font_size() -> int:
	return _font_size


## Returns the font margin
func get_font_margin() -> Vector2:
	return _text_margin


## Returns the size in pixels of the drawn table, not the node size
func get_table_size() -> Vector2:
	return _size_cache


## Gets the Cell at the given position
func get_cell_at_position(p_position: Vector2) -> Cell:
	for row: Row in _rows:
		for cell: Cell in row.get_cells().values():
			if cell.get_rect().has_point(p_position - _get_scroll_offset()):
				return cell
	
	return null


## Returns true if any cells are selected
func is_any_selected() -> bool:
	return bool(_selection.size())


## Emits the selection changed signal, should be called with queue()
func _emit_selection() -> void:
	selection_changed.emit()


## Recomputes dimenctions for the whole table
func _recompute_all() -> void:
	_recompute_rows()
	_recompute_columns()
	

## Recomputes row indexes and table height
func _recompute_rows() -> void:
	_size_cache.y = 0
	
	for row_index: int in range(_rows.size()):
		var row: Row = _rows[row_index]
		
		row._set_index(row_index)
		row._set_position(_size_cache.y)
		
		_size_cache.y += row.get_height()


## Recomputes row indexes and table height
func _recompute_columns() -> void:
	_size_cache.x = 0
	
	for column_index: int in range(_columns.size()):
		var column: Column = _columns[column_index]
		
		column._set_index(column_index)
		column._set_position(_size_cache.x)
		
		_size_cache.x += column.get_width()


## Returns the draw offset, based on scroll
func _get_scroll_offset() -> Vector2:
	return Vector2(
		-_h_scroll_bar.value,
		-_v_scroll_bar.value
	)


## Selects the cell at the given position
func _select_cell_at_position(p_position: Vector2) -> void:
	var cell: Cell = get_cell_at_position(p_position)
	var control_pressed: bool = Input.is_key_pressed(KEY_CTRL)
	
	if not is_instance_valid(cell):
		if not control_pressed:
			deselect_all()
		return
	
	var is_selected: bool = cell.is_selected()
	
	if not control_pressed:
		deselect_all()
	
	cell.set_selected(not is_selected if control_pressed else true)
	queue_redraw_table()


## Called when the select box is moved
func _on_select_box_selection_updated(p_selection: Rect2) -> void:
	var control_pressed: bool = Input.is_key_pressed(KEY_CTRL)
	var shift_pressed: bool = Input.is_key_pressed(KEY_SHIFT)
	
	var flip_x: bool = p_selection.position.x < _select_box.get_start_point().x
	var flip_y: bool = p_selection.position.y < _select_box.get_start_point().y
	
	if not control_pressed:
		deselect_all()
	
	p_selection.position -= _get_scroll_offset()
	
	for row_index: int in range(_rows.size() - 1, -1, -1) if flip_y else range(_rows.size()):
		var row: Row = _rows[row_index]
		var cells: Array = row.get_cells().values()
		
		for cell_index: int in range(cells.size() - 1, -1, -1) if flip_x else range(cells.size()):
			var cell: Cell = cells[cell_index]
			
			if p_selection.intersects(cell.get_rect()):
				cell.set_selected(not shift_pressed)


## Called when this table is resized
func _on_canvas_resized() -> void:
	if not is_node_ready():
		return
	
	_h_scroll_bar.set_visible(_size_cache.x > _canvas.size.x)
	_v_scroll_bar.set_visible(_size_cache.y > _canvas.size.y)
	
	_h_scroll_bar.max_value = _size_cache.x
	_v_scroll_bar.max_value = _size_cache.y
	
	_h_scroll_bar.page = _canvas.size.x
	_v_scroll_bar.page = _canvas.size.y


## Called for all input events on the canvas
func _on_canvas_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseMotion:
		if is_instance_valid(_hovered_cell):
			_hovered_cell._set_hovored(false)
			_hovered_cell = null
		
		var cell: Cell = get_cell_at_position(p_event.position)
		
		if is_instance_valid(cell):
			_hovered_cell = cell
			_hovered_cell._set_hovored(true)
		
		queue_redraw_table()
	
	elif p_event is InputEventMouseButton and p_event.is_pressed():
		match p_event.button_index:
			MOUSE_BUTTON_LEFT:
				_select_cell_at_position(p_event.position)
			MOUSE_BUTTON_RIGHT:
				_on_mouse_button_right_down(p_event)


## Called when MOUSE_BUTTON_RIGHT is pressed
func _on_mouse_button_right_down(p_event: InputEventMouseButton) -> void:
	var cell: Cell = get_cell_at_position(p_event.position)
	
	if get_selection_size() == 1 and not Input.is_key_pressed(KEY_CTRL):
		deselect_all()
	
	if is_instance_valid(cell) and not cell.is_selected():
		cell.set_selected(true)
	
	edit_selected()


## Called when the mouse exits the canvas
func _on_canvas_mouse_exited() -> void:
	if not is_instance_valid(_hovered_cell):
		return
	
	_hovered_cell._set_hovored(false)
	queue_redraw()


## Called when the scroll position is changed on the VScrollBar
func _on_v_scroll_bar_value_changed(_p_value: float) -> void:
	queue_redraw_table()


## Called when the scroll position is changed on the HScrollBar
func _on_h_scroll_bar_value_changed(_p_value: float) -> void:
	queue_redraw_table()


## Class to repersent a Row in the table
class Row extends Object:
	## The Table this row is apart of 
	var _table: Table2
	
	## ID number of this Row
	var _index: int = 0
	
	## Height of this Row
	var _height: int = 30
	
	## Position of this row in local space y
	var _position: int  = 0
	
	## Border color for row borders
	var _border_color: Color = Color(0.29, 0.29, 0.29, 1.0)
	
	## All cells in this Row
	var _cells: Dictionary[Column, Cell]
	
	## Set to store all selected cells in this row
	var _selected_cells: Set = Set.new()
	
	
	## init
	func _init(
		p_table: Table2,
		p_index: int,
		p_height: int = _height,
		p_position: int = _position
	) -> void:
		_table = p_table
		_index = p_index
		_height = p_height
		_position = p_position
	
	
	## Returns, or creates then returns the cell in the given column
	func get_or_create_cell(p_column: Column) -> Cell:
		if _cells.has(p_column):
			return _cells[p_column]
		
		var new_cell: Cell = Cell.new()
		
		add_cell(new_cell, p_column)
		return new_cell
	
	
	## Adds a cell at the given column, must be a new cell
	func add_cell(p_cell: Cell, p_column: Column) -> bool:
		if _cells.has(p_column) or p_cell.get_row() or p_cell.get_column():
			return false
		
		p_cell._set_row(self)
		p_cell._set_column(p_column)
		p_cell._set_table(_table)
		
		_cells[p_column] = p_cell
		
		_table.queue_redraw_table()
		_table.queue_sort()
		return true
	
	
	## Removes a cell from the given column, the cell will be freeded from memeroy
	func remove_cell(p_cell: Cell) -> bool:
		if not _cells.has(p_cell):
			return false
		
		_cells.erase(p_cell)
		p_cell._delete()
		
		_table.queue_redraw_table()
		_table.queue_sort()
		
		return true
	
	
	## Loads data into this row, formated as Column: Data, can be SettingsModules
	func load_data(p_data: Dictionary[Column, Variant]) -> Row:
		for column: Column in p_data:
			if column.get_table() != _table:
				continue
			
			var cell: Cell = get_or_create_cell(column)
			var data: Variant = p_data[column]
			
			if data is SettingsModule:
				cell.use_settings_module(data)
			else:
				cell.set_value(type_convert(data, TYPE_STRING))
		
		return self
	
	
	## Sets the index of this row, ie: moves the row to the given index in the table
	func set_index(p_index: int) -> Row:
		_table.set_row_index(self, p_index)
		return self
	
	
	## Sets the height of this row in pixels
	func set_height(p_height: int) -> Row:
		_table.set_row_height(self, p_height)
		return self
	
	
	## Sets the border color
	func set_border_color(p_color: Color) -> Row:
		_border_color = p_color
		return self 
	
	
	## Returns the index number of this row
	func get_index() -> int:
		return _index
	
	
	## Returns the height in px of this column
	func get_height() -> int:
		return _height
	
	
	## Returns the border color
	func get_border_color() -> Color:
		return _border_color
	
	
	## Returns the vertical positions in pixels this row starts, top left cornor
	func get_position() -> int:
		return _position
	
	
	## Returns all the Cells in this row, keyed by thier Column
	func get_cells() -> Dictionary[Column, Cell]:
		return _cells.duplicate()
	
	
	## Returns the Cell at the given Column, or null
	func get_cell_at_column(p_column: Column) -> Cell:
		return _cells.get(p_column, null)
	
	
	## Returns all the selected cells in this row
	func get_selected_cells() -> Array[Cell]:
		var selected: Array[Cell]
		
		selected.assign(_selected_cells.get_as_array())
		return selected
	
	
	## Returns the table this row in in
	func get_table() -> Table2:
		return _table
	
	
	## Returns the Rect2 for this row
	func get_rect() -> Rect2:
		return Rect2(
			Vector2(
				0,
				_position
			),
			Vector2(
				_table.get_table_size().x,
				_height
			)
		)
	
	
	## Returns true if any cells are selected in this row
	func is_any_selected() -> bool:
		return bool(_selected_cells.size())
	
	
	## Sets the index of this row
	func _set_index(p_index: int) -> void:
		_index = p_index
	
	
	## Sets the height of this row
	func _set_height(p_height: int) -> void:
		_height = p_height
	
	
	## Sets the position of this row
	func _set_position(p_position: int) -> void:
		_position = p_position
	
	
	## Adds or removes the given cell from the selected cells in this row
	func _set_cell_selected(p_cell: Cell, p_selected: bool) -> void:
		if p_selected:
			_selected_cells.add(p_cell)
		else:
			_selected_cells.remove(p_cell)
	
	
	## init
	func _draw(p_canvas: CanvasItem, p_scroll: Vector2 = Vector2.ZERO) -> void:
		for cell: Cell in _cells.values():
			var cell_rect: Rect2 = cell.get_rect()
			
			if cell_rect.position.x > _table._canvas.size.x - p_scroll.x:
				break
			
			if cell_rect.position.x + cell_rect.size.x + p_scroll.x < 0:
				continue
			
			cell._draw(p_canvas, p_scroll)
		
		if _border_color != Color.TRANSPARENT:
			p_canvas.draw_line(
				Vector2(0, _position + _height) + p_scroll, 
				Vector2(_table.get_table_size().x, _position + _height) + p_scroll, 
				_border_color
			)
	
	
	## Cleanup before deletion
	func _delete() -> void:
		_selected_cells.clear()
		for cell: Cell in _cells.values():
			cell._delete()
		
		free()


## Class to repersent a Column in in the table
class Column extends Object:
	## The Table this Column is apart of
	var _table: Table2
	
	## index of this column
	var _index: int = 0
	
	## Width of this Column
	var _width: int = 100
	
	## Position of this column in local space x
	var _position: int = 0
	
	## The title of this Column
	var _title: String
	
	## Border color for coloumn lines
	var _border_color: Color = Color.TRANSPARENT
	
	## Set for all selected cells in this Column
	var _selected_cells: Set = Set.new(TYPE_OBJECT)
	
	
	## init
	func _init(
		p_table: Table2,
		p_index: int, 
		p_width: int = _width, 
		p_position: int = _position,
		p_title: String = _title,
	) -> void:
		_table = p_table
		_index = p_index
		_width = p_width
		_position = p_position
		_title = p_title
	
	
	## Sets the index of this column, moves the column to that index
	func set_index(p_index: int) -> Column:
		_table.set_column_index(self, p_index)
		return self
	
	
	## Sets the width in pixels of this column
	func set_width(p_width: int) -> Column:
		_table.set_column_width(self, p_width)
		return self
	
	
	## Sets the title of this column
	func set_title(p_title: String) -> Column:
		_title = p_title
		
		_table.queue_redraw_table()
		return self
	
	
	## Sets the border color
	func set_border_color(p_color: Color) -> Column:
		_border_color = p_color
		
		_table.queue_redraw_table()
		return self
	
	
	## Gets the index of this Column
	func get_index() -> int:
		return _index
	
	
	## Gets the width of this Column
	func get_width() -> int:
		return _width
	
	
	## Returns the border color
	func get_border_color() -> Color:
		return _border_color
	
	
	## Returns the horisontal position of this column in pixels
	func get_position() -> int:
		return _position
	
	
	## Returns the table this Column in in
	func get_table() -> Table2:
		return _table
	
	
	## Returns all the selected cells in this column
	func get_selected_cells() -> Array[Cell]:
		var selected: Array[Cell]
		
		selected.assign(_selected_cells.get_as_array())
		return selected
	
	
	## Returns true if any cells are selected in this column
	func is_any_selected() -> bool:
		return bool(_selected_cells.size())
	
	
	## Sets the index of this column
	func _set_index(p_index: int) -> void:
		_index = p_index
	
	
	## Sets the width of this column
	func _set_width(p_width: int) -> void:
		_width = p_width
	
	
	## Sets the position of this column
	func _set_position(p_position: int) -> void:
		_position = p_position
	
	
	## Adds or removes the given cell from the selected cells in this column
	func _set_cell_selected(p_cell: Cell, p_selected: bool) -> void:
		if p_selected:
			_selected_cells.add(p_cell)
		else:
			_selected_cells.remove(p_cell)
	
	
	## draw
	func _draw(p_canvas: CanvasItem, p_scroll: Vector2 = Vector2.ZERO) -> void:
		if _border_color != Color.TRANSPARENT:
			p_canvas.draw_line(
				Vector2(_position + _width, 0) + p_scroll,
				Vector2(_position + _width, _table.get_table_size().y) + p_scroll,
				_border_color
			)
	
	
	## Cleanup before deletion
	func _delete() -> void:
		_selected_cells.clear()
		free()


## Class to repersent a cell in Row
class Cell extends Object:
	## The Table this Cell is in
	var _table: Table2
	
	## The row this Cell is in
	var _row: Row
	
	## The Column this Cell is in
	var _column: Column
	
	## String value of this Cell
	var _value: String = ""
	
	## The SettingsModule displayed in this Cell, if any
	var _settings_module: SettingsModule
	
	## Background color of this Cell
	var _bg_color: Color = Color.TRANSPARENT
	
	## Text color of this Cell
	var _text_color: Color = Color(0.869, 0.869, 0.869, 1.0)
	
	## Border color
	var _border_color: Color = Color.TRANSPARENT
	
	## Border width in px
	var _border_width: int = 0
	
	## True if this cell is activley being hovored
	var _is_hovored: bool = false
	
	## True if this cell is selected
	var _is_selected: bool = false
	
	
	## init
	func _init(
		p_value: String = _value, 
		p_bg_color: Color = _bg_color, 
		p_text_color: Color = _text_color,
		p_border_color: Color = _border_color,
		p_border_width: int = _border_width
	) -> void:
		_value = p_value
		_bg_color = p_bg_color
		_text_color = p_text_color
		_border_color = p_border_color
		_border_width = p_border_width
	
	
	## Sets this Cell to display the value of a SettingsModule
	func use_settings_module(p_settings_module: SettingsModule) -> Cell:
		if is_instance_valid(_settings_module):
			_settings_module.unsubscribe(_on_settings_module_value_changed)
			_settings_module.disconnect_name_signal(_on_settings_module_name_changed)
		
		_settings_module = p_settings_module
		
		if is_instance_valid(_settings_module):
			_settings_module.subscribe(_on_settings_module_value_changed)
			_settings_module.connect_name_signal(_on_settings_module_name_changed)
			
			set_value(_settings_module.get_value_string())
		else:
			set_value("")
		
		return self
	
	
	## Sets the value of this Cell
	func set_value(p_value: String) -> Cell:
		_value = p_value
		
		if is_instance_valid(_table) and _table.get_sort_column() == _column:
			_table.queue_sort()
		
		_queue_redraw()
		return self
	
	
	## Sets the cell background color
	func set_bg_color(p_bg_color: Color) -> Cell:
		_bg_color = p_bg_color
		
		_queue_redraw()
		return self
	
	
	## Sets the text color
	func set_text_color(p_text_color: Color) -> Cell:
		_text_color = p_text_color
		
		_queue_redraw()
		return self
	
	
	## Sets the cell border color
	func set_border_color(p_border_color: Color) -> Cell:
		_border_color = p_border_color
		
		_queue_redraw()
		return self
	
	
	## Sets the border width in px
	func set_border_width(p_border_width: int) -> Cell:
		_border_width = p_border_width
		
		_queue_redraw()
		return self
	
	
	## Sets the selected state
	func set_selected(p_selected: bool) -> void:
		if is_instance_valid(_table):
			_table.set_cell_selected(self, p_selected)
	
	
	## Returns the SettingsModule displayed by this cell, or null
	func get_settings_module() -> SettingsModule:
		return _settings_module
	
	
	## Returns the value of this cell
	func get_value() -> String:
		return _value
	
	
	## Returns the background color of this cell
	func get_bg_color() -> Color:
		return _bg_color
	
	
	## Returns the text color of this cell
	func get_text_color() -> Color:
		return _text_color
	
	
	## Returns the border color of this cell
	func get_border_color() -> Color:
		return _border_color
	
	
	## Returns the border width in pixels
	func get_border_width() -> int:
		return _border_width
	
	
	## Returns the selected state
	func get_selected() -> bool:
		return _is_selected
	
	
	## Returns the hovored state
	func get_hovored() -> bool:
		return _is_hovored
	
	
	## Returns a Rect2 with the position and size of this cell
	func get_rect() -> Rect2:
		return Rect2(
			Vector2(
				_column.get_position(), 
				_row.get_position()
			),
			Vector2(
				_column.get_width(),
				_row.get_height()
			)
		)
	
	
	## Returns the Table this Cell is in
	func get_table() -> Table2:
		return _table
	
	
	## Returns the Row this Cell is in
	func get_row() -> Row:
		return _row
	
	
	## Returns the Column this Cell is in
	func get_column() -> Column:
		return _column
	
	
	## Returns the selected state of this Cell
	func is_selected() -> bool:
		return _is_selected
	
	
	## Returns true if this Cell is displaying a SettingsModule
	func is_using_settings_module() -> bool:
		return is_instance_valid(_settings_module)
	
	
	## Sets the selected state
	func _set_selected(p_selected: bool) -> void:
		_is_selected = p_selected
		
		_row._set_cell_selected(self, p_selected)
		_column._set_cell_selected(self, p_selected)
	
	
	## Sets the hovored state
	func _set_hovored(p_hovored: bool) -> void:
		_is_hovored = p_hovored
	
	
	## Sets the parent row
	func _set_row(p_row: Row) -> void:
		_row = p_row
	
	
	## Sets the parent column
	func _set_column(p_column: Column) -> void:
		_column = p_column
	
	
	## Sets the parent table
	func _set_table(p_table: Table2) -> void:
		_table = p_table
	
	
	## Queue redraw the table if its valid
	func _queue_redraw() -> void:
		if is_instance_valid(_table):
			_table.queue_redraw_table()
	
	
	## draw
	func _draw(p_canvas: CanvasItem, p_scroll: Vector2 = Vector2.ZERO) -> void:
		var rect: Rect2 = get_rect()
		var font_size: int = _table.get_font_size()
		rect.position += p_scroll
		
		var font_pos: Vector2 = rect.position + Vector2(
			0, 
			rect.size.y/2 + font_size / 2
		) + _table.get_font_margin()
		
		p_canvas.draw_rect(rect, _bg_color)
		
		if _is_selected:
			p_canvas.draw_rect(rect, _table.CELL_SELECT_COLOR)
		
		if _is_hovored:
			p_canvas.draw_rect(rect, _table.CELL_HOVER_COLOR)
		
		if _row.is_any_selected() and not _is_selected:
			p_canvas.draw_rect(rect, _table.ROW_HILIGHT_COLOR)
		
		if _border_width and _border_color != Color.TRANSPARENT:
			p_canvas.draw_rect(rect.grow(-_border_width / 2), _border_color, false, _border_width)
		
		p_canvas.draw_string(
			_table.get_font(), 
			font_pos, 
			_value, 
			HORIZONTAL_ALIGNMENT_LEFT, 
			rect.size.x, 
			font_size, 
			_text_color.lightened(_table.CELL_TEXT_SELECTED_LIGHTEN if _is_selected else 0) 
		)
	
	
	## Cleanup before deletion
	func _delete() -> void:
		if _is_selected:
			set_selected(false)
		
		if is_instance_valid(_settings_module):
			use_settings_module(null)
		
		free()
	
	
	## Called when the settings module value is changed
	func _on_settings_module_value_changed(...p_args: Array) -> void:
		set_value(_settings_module.get_value_string())
	
	
	## Called when the name of a settings module value is changed
	func _on_settings_module_name_changed(p_name: String) -> void:
		set_value(p_name)
