# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIObjectSelector extends UIPopup
## Find and selects objects


## Emitted when a GBCIndexConfig is selected
signal gbc_index_selected(p_gbc_index: GBCIndexConfig)

## Emitted when an object is selected
signal object_selected(p_object: Object)

## Emitted when a class is selected
signal class_selected(p_class: String)


## Enum for SelectMode
enum SelectMode {
	NONE,			## No SelectMode
	GBC_INDEX,		## Selects a GBCIndexConfig
	GBC_OBJECT,		## GBC_INDEX then OBJECT
	GBC_CLASS,		## GBC_INDEX then CLASS
	OBJECT, 		## Selects a pre-existing object
	CLASS			## Selects a classname
}


## The LineEdit search bar
@onready var _search_bar: TaggedLineEdit = %SearchBar

## The Container to hold all SearchableClassTrees
@onready var _index_container: Container = %IndexContainer

## The GBCIndex tree
@onready var _gbc_index_tree: Tree = %GBCIndexTree


## All Indexes shown
var _indexes: RefMap = RefMap.new()

## The current index
var _current_index: SearchableClassTree

## Current select mode
var _select_mode: SelectMode = SelectMode.NONE

## The previous select mode 
var _previous_select_mode: SelectMode = SelectMode.NONE

## RefMap for GBCIndex: TreeItem
var _gbc_index_items: RefMap = RefMap.new()

## The class filter defined when this UIObjectSelector was opened, back button wont proceed higher then this class
var _min_class_filter: String


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	
	_set_class_name("UIObjectSelector")


## Ready
func _ready() -> void:
	super._ready()
	
	_gbc_index_tree.set_columns(2)
	_gbc_index_tree.create_item()
	
	_gbc_index_tree.set_column_expand(1, false)
	_gbc_index_tree.set_column_custom_minimum_width(1, 100)
	
	var gbc_null: TreeItem = _gbc_index_tree.create_item()
	
	gbc_null.set_icon(0, UIDB.get_class_icon("null"))
	gbc_null.set_text(0, "null")
	gbc_null.set_text(1, "Empty")
	
	for gbc_class: String in Data.Config.gbc_index:
		var config: GBCIndexConfig = Data.get_gbc_config(gbc_class)
		var class_tree: SearchableClassTree = UIDB.instance_component(SearchableClassTree)
		
		class_tree.class_filter_changed.connect(_on_class_filter_changed.bind(class_tree))
		class_tree.object_selected.connect(accept)
		class_tree.class_selected.connect(accept)
		
		_index_container.add_child(class_tree)
		_indexes.map(gbc_class, class_tree)
		
		class_tree.load_config(config)
		class_tree.hide()
		
		var gbc_item: TreeItem = _gbc_index_tree.create_item()
		
		gbc_item.set_text(0, gbc_class)
		gbc_item.set_icon(0, UIDB.get_class_icon(gbc_class))
		
		gbc_item.set_custom_color(1, Color(0x919191ff))
		gbc_item.set_text(1, "Use")
		
		_gbc_index_items.map(config, gbc_item)
	
	get_edit_controls().back_button.pressed.connect(go_back)
	get_edit_controls().back_button.set_disabled(true)


## Sets the SelectMode to SelectMode.GBC_INDEX
func select_mode_gbc_index() -> void:
	_previous_select_mode = SelectMode.GBC_INDEX
	set_custom_accepted_signal(gbc_index_selected)
	_set_select_mode_gbc_index()


## Sets the SelectMode to SelectMode.GBC_INDEX
func select_mode_gbc_object() -> void:
	_previous_select_mode = SelectMode.GBC_OBJECT
	set_custom_accepted_signal(object_selected)
	_set_select_mode_gbc_object()


## Sets the SelectMode to SelectMode.GBC_INDEX
func select_mode_gbc_class() -> void:
	_previous_select_mode = SelectMode.GBC_CLASS
	set_custom_accepted_signal(class_selected)
	_set_select_mode_gbc_class()


## Sets the SelectMode to SelectMode.GBC_INDEX
func select_mode_object(p_gbc_class: Variant, p_class_filter: Variant = "") -> void:
	_previous_select_mode = SelectMode.OBJECT
	set_custom_accepted_signal(object_selected)
	_set_select_mode_object(p_gbc_class, p_class_filter)


## Sets the SelectMode to SelectMode.CLASS
func select_mode_class(p_gbc_class: Variant, p_class_filter: Variant = "") -> void:
	_previous_select_mode = SelectMode.CLASS
	set_custom_accepted_signal(class_selected)
	
	_set_select_mode_class(p_gbc_class, p_class_filter)


## Resets this UIObjectSelector
func reset() -> void:
	_search_bar.clear_all()
	_select_mode = SelectMode.NONE
	
	if is_instance_valid(_current_index):
		_current_index.hide()
	
	_gbc_index_tree.hide()
	_current_index = null
	_min_class_filter = ""
	get_edit_controls().back_button.set_disabled(true)


## Sets the search filter
func search_for(p_text: String) -> void:
	if _current_index:
		_current_index.search_for(p_text)


## Makes this take focus
func focus() -> void:
	await get_tree().process_frame
	
	_search_bar.grab_focus()
	_search_bar.edit()


## Goes back one level in the class tree
func go_back() -> void:
	if not is_instance_valid(_current_index):
		return
	
	var current_filter: String = _current_index.get_class_filter()
	var classdb: CoreClassListDB = _current_index.get_config().get_class_listdb()
	var parent_class: String = classdb.get_class_parent(current_filter)
	
	match _previous_select_mode:
		SelectMode.GBC_OBJECT when not parent_class:
			_set_select_mode_gbc_object()
		SelectMode.GBC_CLASS when not parent_class:
			_set_select_mode_gbc_class()
		_:
			if _is_higher_then_filer(parent_class, classdb):
				get_edit_controls().back_button.set_disabled(true)
			else:
				_current_index.search_mode_object(parent_class)
			
			_update_menu_bar_items(_current_index)


## Sets the SelectMode to SelectMode.GBC_INDEX
func _set_select_mode_gbc_index() -> void:
	reset()
	_select_mode = SelectMode.GBC_INDEX
	
	_search_bar.set_placeholder("Select GBCIndex")
	
	_gbc_index_tree.show()
	focus.call_deferred()


## Sets the SelectMode to SelectMode.GBC_OBJECT
func _set_select_mode_gbc_object() -> void:
	_set_select_mode_gbc_index()
	_search_bar.set_placeholder("Select GBCIndex > Object")


## Sets the SelectMode to SelectMode.GBC_CLASS
func _set_select_mode_gbc_class() -> void:
	_set_select_mode_gbc_index()
	_search_bar.set_placeholder("Select GBCIndex > Class")


## Sets the SelectMode to SelectMode.OBJECT
func _set_select_mode_object(p_gbc_class: Variant, p_class_filter: Variant = "") -> void:
	reset()
	
	_select_mode = SelectMode.OBJECT
	_search_bar.set_placeholder("Select Object")
	
	_set_index(p_gbc_class, p_class_filter, true)
	focus.call_deferred()


## Sets the SelectMode to SelectMode.CLASS
func _set_select_mode_class(p_gbc_class: Variant, p_class_filter: Variant = "") -> void:
	reset()
	
	_select_mode = SelectMode.CLASS
	_search_bar.set_placeholder("Select Class")
	
	_set_index(p_gbc_class, p_class_filter, true)
	focus.call_deferred()


## Sets the index by base script
func _set_index(p_class: Variant, p_class_filter: Variant = "", p_set_min_filter: bool = false) -> bool:
	if p_class is Script:
		p_class = p_class.get_global_name()
	
	if p_class_filter is Script:
		p_class_filter = p_class_filter.get_global_name()
	
	p_class = type_convert(p_class, TYPE_STRING)
	p_class_filter = type_convert(p_class_filter, TYPE_STRING)
	
	if not _indexes.has_left(p_class):
		return false
	
	if not p_class_filter:
		p_class_filter = p_class
	
	if _current_index:
		_current_index.hide()
	
	if p_set_min_filter:
		_min_class_filter = p_class_filter
	
	_search_bar.clear_tags()
	_search_bar.clear()
	
	_current_index = _indexes.left(p_class)
	_current_index.show()
	
	match _select_mode:
		SelectMode.OBJECT:
			_current_index.search_mode_object(p_class_filter)
		SelectMode.CLASS:
			_current_index.search_mode_class(p_class_filter)
	
	_update_menu_bar_items(_current_index)
	return true


## Selectes the next item in the given tree
func _select_next(p_tree: Tree) -> void:
	var current: TreeItem = p_tree.get_selected()
	var next_item: TreeItem = current.get_next_visible(true) if current else p_tree.get_root().get_child(0)
	
	if next_item:
		next_item.select(0)
	
	p_tree.ensure_cursor_is_visible()


## Selectes the next item in the given tree
func _select_prev(p_tree: Tree) -> void:
	var current: TreeItem = p_tree.get_selected()
	var next_item: TreeItem = current.get_prev_visible(true) if current else p_tree.get_root().get_child(0)
	
	if next_item:
		next_item.select(0)
	
	p_tree.ensure_cursor_is_visible()


## Updates the search bar tag and back button
func _update_menu_bar_items(p_class_tree: SearchableClassTree) -> void:
	var class_filter: String = p_class_tree.get_class_filter()
	var is_top_level: bool = class_filter == p_class_tree.get_config().get_base_class().get_global_name()
	
	_search_bar.clear_all()
	_add_filter_tag(p_class_tree)
	
	_search_bar.grab_focus()
	_search_bar.edit()
	
	match _previous_select_mode:
		SelectMode.GBC_OBJECT, SelectMode.GBC_CLASS:
			get_edit_controls().back_button.set_disabled(false)
		_:
			if _is_higher_then_filer(class_filter, p_class_tree.get_config().get_class_listdb(), true):
				get_edit_controls().back_button.set_disabled(true)
				
			else:
				get_edit_controls().back_button.set_disabled(is_top_level)


## Adds a tag to the TaggedLineEdit for the current clas filter
func _add_filter_tag(p_class_tree: SearchableClassTree) -> void:
	var text: String = ""
	var config: GBCIndexConfig = p_class_tree.get_config()
	var class_filter: String = p_class_tree.get_class_filter()
	
	if not class_filter:
		class_filter = str(config.get_base_class().get_global_name())
	
	for classname: String in config.get_class_listdb().get_class_inheritance_tree(class_filter):
		text += classname + "/"
	
	if not text:
		text = class_filter
	
	_search_bar.create_tag("@" + text)


## Called when text is submitted
func _handle_activated() -> void:
	match _select_mode:
		SelectMode.GBC_INDEX:
			var gbc_index: GBCIndexConfig = _gbc_index_items.right(_gbc_index_tree.get_selected(), null)
			
			match _previous_select_mode:
				SelectMode.GBC_OBJECT when is_instance_valid(gbc_index):
					_set_select_mode_object(gbc_index.get_base_class(), "")
				
				SelectMode.GBC_CLASS when is_instance_valid(gbc_index):
					_set_select_mode_class(gbc_index.get_base_class())
				
				_:
					accept(gbc_index)
		
		SelectMode.OBJECT, SelectMode.CLASS when is_instance_valid(_current_index):
			_current_index.activate_selected()


## Returns true if the given class is higher then the highest class defined when the object selector was opened
func _is_higher_then_filer(p_class: String, p_class_db: CoreClassListDB, p_true_if_match: bool = false) -> bool:
	if _min_class_filter or not p_class and not p_class_db.does_class_inherit(p_class, _min_class_filter) or (p_class == _min_class_filter and p_true_if_match):
		return true
	else:
		return false


## Called when the SearchMode is changed in a SearchableClassTree
func _on_class_filter_changed(p_class_filter: String, p_class_tree: SearchableClassTree) -> void:
	if p_class_tree != _current_index:
		return
	
	_update_menu_bar_items(p_class_tree)


## Called when a tag is removed from the search bar
func _on_line_edit_tag_removed(_p_id: Variant) -> void:
	go_back()


## Called for all GUI inputs on the search bar
func _on_line_edit_gui_input(p_event: InputEvent) -> void:
	match _select_mode:
		SelectMode.GBC_INDEX:
			if p_event.is_action_pressed("ui_down"):
				_select_next(_gbc_index_tree)
			
			if p_event.is_action_pressed("ui_up"):
				_select_prev(_gbc_index_tree)
		
		SelectMode.OBJECT, SelectMode.CLASS when is_instance_valid(_current_index):
			if p_event.is_action_pressed("ui_down"):
				_current_index.select_next()
			
			if p_event.is_action_pressed("ui_up"):
				_current_index.select_prev()
