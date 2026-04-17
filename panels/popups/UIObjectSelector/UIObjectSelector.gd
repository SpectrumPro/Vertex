# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name UIObjectSelector extends UIPopup
## Find and selects objects


## Emitted when an object is selected
signal object_selected(p_object: Variant)


## Enum for SelectMode
enum SelectMode {
	OBJECT, 		## Selects a pre-existing object
	CLASS			## Selects a classname
}


## The LineEdit search bar
@export var search_bar: TaggedLineEdit

## The Container to hold all SearchableClassTrees
@export var index_container: Container


## All Indexes shown
var _indexes: RefMap = RefMap.new()

## The current index
var _current_index: SearchableClassTree

## Current select mode
var _select_mode: SelectMode = SelectMode.OBJECT


## init
func _init(p_uuid: String = UUID.v4(), ...p_args: Array[Variant]) -> void:
	super._init(p_uuid, p_args)
	
	_set_class_name("UIObjectSelector")
	set_custom_accepted_signal(object_selected)


## Ready
func _ready() -> void:
	super._ready()
	
	for gbc_class: String in Data.Config.gbc_index:
		var config: GBCIndexConfig = Data.get_gbc_config(gbc_class)
		var class_tree: SearchableClassTree = UIDB.instance_component(SearchableClassTree)
		
		class_tree.search_mode_changed.connect(_on_search_mode_changed.bind(class_tree))
		class_tree.object_selected.connect(accept)
		class_tree.class_selected.connect(accept)
		
		class_tree.load_config(config)
		class_tree.hide()
		
		index_container.add_child(class_tree)
		_indexes.map(gbc_class, class_tree)
	
	get_edit_controls().back_button.pressed.connect(go_back)
	get_edit_controls().back_button.set_disabled(true)


## Sets the index by base script
func set_index(p_class: Variant, p_class_filter: Variant = "") -> bool:
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
	
	search_bar.clear_tags()
	search_bar.clear()
	
	_current_index = _indexes.left(p_class)
	_current_index.show()
	
	match _select_mode:
		SelectMode.OBJECT:
			_current_index.search_mode_object(p_class_filter)
		SelectMode.CLASS:
			_current_index.search_mode_class(p_class_filter)
	
	return true


## Sets the select mode
func set_select_mode(p_select_mode: SelectMode) -> void:
	_select_mode = p_select_mode
	
	if not is_instance_valid(_current_index):
		return
	
	match _select_mode:
		SelectMode.OBJECT:
			_current_index.search_mode_combined()
			
		SelectMode.CLASS:
			_current_index.search_mode_class()


## Sets the search filter
func search_for(p_text: String) -> void:
	if _current_index:
		_current_index.search_for(p_text)


## Makes this take focus
func focus() -> void:
	search_bar.grab_focus()


## Goes back one level in the class tree
func go_back() -> void:
	if not is_instance_valid(_current_index):
		return
	
	var current_filter: String = _current_index.get_object_class()
	var parent_class: String = _current_index.get_config().get_class_listdb().get_class_parent(current_filter)
	
	_current_index.search_mode_object(parent_class)


## Called when the SearchMode is changed in a SearchableClassTree
func _on_search_mode_changed(p_search_mode: SearchableClassTree.SearchMode, p_class_tree: SearchableClassTree) -> void:
	if p_class_tree != _current_index:
		return
	
	match p_search_mode:
		SearchableClassTree.SearchMode.OBJECT:
			search_bar.clear_all()
			_add_filter_tag(p_class_tree)
			
			search_bar.grab_focus()
			search_bar.edit()
			
			var is_top_level: bool = p_class_tree.get_object_class() == p_class_tree.get_config().get_base_class().get_global_name()
			get_edit_controls().back_button.set_disabled(is_top_level)
		
		_:
			get_edit_controls().back_button.set_disabled(true)


## Adds a tag to the TaggedLineEdit for the current clas filter
func _add_filter_tag(p_class_tree: SearchableClassTree) -> void:
	var text: String = "@"
	var config: GBCIndexConfig = p_class_tree.get_config()
	var class_filter: String = p_class_tree.get_object_class()
	
	if not class_filter:
		class_filter = str(config.get_base_class().get_global_name())
	
	for classname: String in config.get_class_listdb().get_class_inheritance_tree(class_filter):
		text += classname + "/"
		
	search_bar.create_tag(text)


## Called when a tag is removed from the search bar
func _on_line_edit_tag_removed(_p_id: Variant) -> void:
	go_back()


## Called for all GUI inputs on the search bar
func _on_line_edit_gui_input(p_event: InputEvent) -> void:
	if not _current_index:
		return
	
	if p_event.is_action_pressed("ui_down"):
		_current_index.select_next()
	
	if p_event.is_action_pressed("ui_up"):
		_current_index.select_prev()


## Called when text is submitted
func _on_line_edit_text_submitted(_p_new_text: String) -> void:
	if _current_index:
		_current_index.activate_selected()
