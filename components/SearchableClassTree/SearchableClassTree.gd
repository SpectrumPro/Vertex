# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details.

class_name SearchableClassTree extends UIComponent
## A tree containing a list of classes that are searchable


## Emitted when the class filter is changed, only emitted in SearchMode.OBJECT
signal class_filter_changed(filter: String)

## Emitted when an object is selected
signal object_selected(object: Object)

## Emitted when a class is selected
signal class_selected(classname: String)


## Enum for SearchMode
enum SearchMode {
	NONE,		## No selected SearchMode
	OBJECT,		## Search for objects in a GBCIndex
	CLASS,		## Search for classes in a GBCIndex
}


## Min size of the second tree column
const COLUMN_MIN_SIZE: int = 150


## The InheritanceTree
@onready var _class_inhr_tree: Tree = %ClassInhrTree

## The SearchableTree
@onready var _class_list: Tree = %ClassList

## The ObjectInheritanceTree
@onready var _objecet_inhr_tree: Tree = %ObjectInhrTree

## The ObjectTree
@onready var _object_list: Tree = %ObjectList


## The ClassTreeConfig
var _config: GBCIndexConfig

## RefMap for TreeItem: "ClassName". for _class_inhr_tree and _class_list
var _class_items: RefMap = RefMap.new()

## RefMap for TreeItem: Object. for _object_list
var _object_items: RefMap = RefMap.new()

## RefMap for TreeItem: Object's "ClassName". For _objecet_inhr_tree
var _object_inher_class_items: RefMap = RefMap.new()

## RefMap for TreeItem: Object. For _objecet_inhr_tree
var _object_inher_object_items: RefMap = RefMap.new()

## Set for all visable object_inher_class_items
var _visable_object_inher_class_items: Set = Set.new()

## The null item in the _class_inhr_tree
var _inheritance_tree_null: TreeItem

## All tree nulls
var _tree_nulls: RefMap

## Current search mode
var _search_mode: SearchMode = SearchMode.NONE

## The class filter given when selecting the SearchMode
var _class_filter: String = ""

## The class filter defined when a searchmode was selectod.
var _orignal_class_filter: String = ""

## The current search text
var _search_text: String = ""


## Init
func _init() -> void:
	super._init()
	_set_class_name("SeachableClassTreee")


## Ready
func _ready() -> void:
	_tree_nulls = RefMap.from({
		_class_inhr_tree: null,
		_class_list: null,
		_object_list: null,
		_objecet_inhr_tree: null
	})
	
	_tree_nulls.get_left().map(func (tree: Tree):
		tree.set_column_expand(1, false)
		tree.set_column_custom_minimum_width(1, COLUMN_MIN_SIZE)
	)


## Loads a ClassTreeConfig
func load_config(p_config: GBCIndexConfig) -> void:
	_config = p_config
	
	_class_inhr_tree.clear()
	_class_list.clear()
	_objecet_inhr_tree.clear()
	
	_class_inhr_tree.create_item()
	_class_list.create_item()
	_objecet_inhr_tree.create_item()
	
	_inheritance_tree_null = _class_inhr_tree.get_root().create_child()
	_inheritance_tree_null.set_text(0, "null")
	_inheritance_tree_null.set_text(1, "Empty")
	_inheritance_tree_null.set_icon(0, UIDB.get_class_icon("null"))
	
	var class_tree: Dictionary = _config.get_class_listdb().get_global_class_tree()
	if not _class_inhr_tree:
		return
	
	_climb_branch_tree(_class_inhr_tree.get_root(), _objecet_inhr_tree.get_root(), class_tree, class_tree.keys()[0])


## Sets the search mode to SearchMode.CLASS
func search_mode_class(p_class_filter: String = "") -> void:
	_search_mode = SearchMode.CLASS
	_class_filter = p_class_filter
	_orignal_class_filter = p_class_filter
	
	search_for("")


## Sets the search mode to SearchMode.OBJECT
func search_mode_object(p_classname: String = "") -> void:
	_orignal_class_filter = p_classname
	_set_search_mode_object(p_classname)


## Selectes the next item in the tree
func select_next() -> void:
	var tree: Tree = _get_active_tree()
	var current: TreeItem = tree.get_selected()
	var next_item: TreeItem = current.get_next_visible(true) if current else tree.get_root().get_child(0)
	
	if next_item:
		next_item.select(0)
	
	tree.ensure_cursor_is_visible()


## Selectes the next item in the tree
func select_prev() -> void:
	var tree: Tree = _get_active_tree()
	var current: TreeItem = tree.get_selected()
	var next_item: TreeItem = current.get_prev_visible(true) if current else tree.get_root().get_child(0)
	
	if next_item:
		next_item.select(0)
	
	tree.ensure_cursor_is_visible()

 
## Activates the selected TreeItem
func activate_selected() -> void:
	var tree: Tree = _get_active_tree()
	var selected: TreeItem = tree.get_selected()
	
	if not selected or selected == tree.get_root():
		return
	
	if _tree_nulls.has_right(selected):
		object_selected.emit(null)
	
	match _search_mode:
		SearchMode.CLASS:
			class_selected.emit(selected.get_text(0))
		
		SearchMode.OBJECT when _search_text:
			object_selected.emit(_object_items.left(selected))
		
		SearchMode.OBJECT when not _search_text:
			if _object_inher_class_items.has_left(selected):
				var classname: String = _object_inher_class_items.left(selected)
				
				if not _is_higher_then_filer(classname):
					_set_search_mode_object(classname)
					class_filter_changed.emit(classname)
			
			else:
				object_selected.emit(_object_inher_object_items.left(selected))


## Focuses the current Tree
func focus() -> void:
	_get_active_tree().grab_focus()


## Searches for the given text
func search_for(p_text: String) -> void:
	var items_to_display: Array[Dictionary]
	var search_tree: Tree = null
	var item_to_select: TreeItem = null
	
	_search_text = p_text.to_lower()
	
	_object_list.hide()
	_objecet_inhr_tree.hide()
	_class_list.hide()
	_class_inhr_tree.hide()
	
	match _search_mode:
		SearchMode.CLASS when _search_text == "":
			_class_inhr_tree.show()
			search_tree = _class_inhr_tree
			
			for item: TreeItem in _class_inhr_tree.get_root().get_children():
				if item.get_text(0) == _class_filter and _class_filter:
					item_to_select = item
					item.set_visible(true)
				else:
					item.set_visible(false)
			
		SearchMode.CLASS:
			if not _search_text:
				_class_inhr_tree.show()
				return
			
			_class_list.show()
			search_tree = _class_list
			
			for classname: String in _class_items.get_right():
				var should_show: bool = _search_mode == SearchMode.CLASS and _config.get_class_listdb().does_class_inherit(classname, _class_filter)
				items_to_display.append({
					"item_name": classname,
					"similarity": classname.similarity(_search_text) if _search_text else 0.0,
					"tree_item": _class_items.right(classname),
					"show": should_show
				})
		
		SearchMode.OBJECT:
			if not _search_text:
				_objecet_inhr_tree.show()
				return
			
			_object_list.show()
			search_tree = _object_list
			
			for object: Object in _object_items.get_right():
				var object_name: String = object.get_uname()
				items_to_display.append({
					"item_name": object_name,
					"similarity": object_name.similarity(_search_text) if p_text else 0.0,
					"tree_item": _object_items.right(object),
					"show": true
				})
	
	items_to_display.sort_custom(func (p_a: Dictionary, p_b: Dictionary) -> bool:
		if _search_text and len(_search_text) < 3:
			return (p_a.item_name as String).to_lower().begins_with(_search_text[0])
		elif _search_text:
			return p_a.similarity > p_b.similarity
		else:
			return (p_a.item_name as String).naturalnocasecmp_to(p_b.item_name) < 0
	)
	items_to_display.reverse()
	
	for item: Dictionary in items_to_display:
		item.tree_item.move_before(search_tree.get_root().get_child(0))
		item.tree_item.set_visible(item.show)
	
	if item_to_select:
		item_to_select.select(0)
		search_tree.ensure_cursor_is_visible()
	
	elif search_tree.get_root().get_child_count():
		search_tree.get_root().get_child(0).select(0)
		search_tree.ensure_cursor_is_visible()
	
	_show_null()


## Gets the loaded config
func get_config() -> GBCIndexConfig:
	return _config


## Gets the filter used for SearchMode.CLASS
func get_class_filter() -> String:
	return _class_filter


## Shows a "null" item on each tree
func _show_null() -> void:
	for tree: Tree in _tree_nulls.get_left():
		if not _tree_nulls.left(tree):
			var new_null: TreeItem = tree.create_item()
			
			new_null.set_text(0, "null")
			new_null.set_text(1, "Empty")
			new_null.set_icon(0, UIDB.get_class_icon("null"))
			
			_tree_nulls.map(tree, new_null)
		
		var tree_null: TreeItem = _tree_nulls.left(tree)
		tree_null.set_visible(true)
		
		if tree.get_root().get_children():
			tree_null.move_before(tree.get_root().get_child(0))


## Climbs a branch on the class tree
func _climb_branch_tree(p_class_inhr_tree: TreeItem, p_object_inhr: TreeItem, p_data_branch: Dictionary, p_previous_classname: String) -> void:
	for classname: String in p_data_branch.keys():
		if _config.get_class_listdb().is_class_hidden(classname):
			continue
		
		var value: Variant = p_data_branch[classname]
		var class_inhr_branch = p_class_inhr_tree.create_child()
		
		class_inhr_branch.set_text(0, classname)
		class_inhr_branch.set_icon(0, UIDB.get_class_icon(classname))
		
		class_inhr_branch.set_custom_color(1, Color(0x919191ff))
		class_inhr_branch.set_text(1, "Class")
		
		var object_inhr_branch = p_object_inhr.create_child()
		_object_inher_class_items.map(object_inhr_branch, classname)
		object_inhr_branch.set_visible(false)
		
		object_inhr_branch.set_text(0, classname)
		object_inhr_branch.set_icon(0, UIDB.get_class_icon(classname))
		
		object_inhr_branch.set_icon_modulate(0, Color(0x919191ff))
		object_inhr_branch.set_custom_color(0, Color(0x919191ff))
		
		object_inhr_branch.set_custom_color(1, Color(0x919191ff))
		object_inhr_branch.set_text(1, "Class")
		
		if value is Dictionary:
			_climb_branch_tree.call(class_inhr_branch, object_inhr_branch, value, classname)
		
		elif value is Script:
			var flat_item: TreeItem = _class_list.create_item()
			
			flat_item.set_text(0, classname)
			flat_item.set_icon(0, UIDB.get_class_icon(classname))
			
			flat_item.set_custom_color(1, Color(0x919191ff))
			flat_item.set_text(1, p_previous_classname)
			
			_class_items.map(flat_item, classname)


## Sets the SearchMode to OBJECT
func _set_search_mode_object(p_class_filter: String) -> void:
	if not p_class_filter:
		p_class_filter = _config.get_base_class().get_global_name()
	
	_search_mode = SearchMode.OBJECT
	_class_filter = p_class_filter
	
	_object_list.clear()
	_object_list.create_item()
	_object_items.clear()
	
	for item: TreeItem in _object_inher_object_items.get_left():
		item.free()
	
	for item: TreeItem in _visable_object_inher_class_items.get_as_array():
		item.set_visible(false)
	
	_visable_object_inher_class_items.clear()
	_object_inher_object_items.clear()
	
	for object: Object in _config.get_objectdb().get_components_by_classname(p_class_filter):
		_add_object_tree_item(object)
	
	for item: TreeItem in _visable_object_inher_class_items.get_as_array():
		while is_instance_valid(item) and not item.is_visible():
			item.set_visible(true)
			_visable_object_inher_class_items.add(item)
			item = item.get_parent()
	
	search_for("")


## Adds an item to the object tree
func _add_object_tree_item(p_object: Object) -> void:
	var classname: String = p_object.get_class_name()
	if _config.get_class_listdb().is_class_hidden(classname):
		return
	
	var flat_object_item: TreeItem = _object_list.create_item()
	_object_items.map(flat_object_item, p_object)
	
	flat_object_item.set_text(0, p_object.get_uname())
	flat_object_item.set_icon(0, UIDB.get_class_icon(classname))
	
	flat_object_item.set_custom_color(1, Color(0x919191ff))
	flat_object_item.set_text(1, classname)
	
	var inhr_class_item: TreeItem = _object_inher_class_items.right(classname)
	var inhr_object_item: TreeItem = inhr_class_item.create_child()
	
	_object_inher_object_items.map(inhr_object_item, p_object)
	_visable_object_inher_class_items.add(inhr_class_item)
	
	inhr_object_item.set_text(0, p_object.get_uname())
	inhr_object_item.set_icon(0, UIDB.get_class_icon(classname))
	
	inhr_object_item.set_custom_color(1, Color(0x919191ff))
	inhr_object_item.set_text(1, "Object")


## Gets the active tree
func _get_active_tree() -> Tree:
	match _search_mode:
		SearchMode.CLASS when _search_text:
			return _class_list
		
		SearchMode.CLASS when not _search_text:
			return _class_inhr_tree
		
		SearchMode.OBJECT when _search_text:
			return _object_list
		
		SearchMode.OBJECT when not _search_text:
			return _objecet_inhr_tree
		
		_:
			return null

## Returns true if the given class is higher then the highest class defined when the object selector was opened
func _is_higher_then_filer(p_class: String) -> bool:
	if _orignal_class_filter and not _config.get_class_listdb().does_class_inherit(p_class, _orignal_class_filter):
		return true
	else:
		return false
