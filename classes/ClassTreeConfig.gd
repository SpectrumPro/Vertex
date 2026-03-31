# Copyright (c) 2026 Liam Sherwin. All rights reserved.
# This file is part of the Spectrum Lighting Controller, licensed under the GPL v3.0 or later.
# See the LICENSE file for details

class_name ClassTreeConfig extends Object
## Config entry for SearchableClassTree


## The base class
var _base_class: Script

## The ObjectDB for the base class
var _objectdb: ObjectDB

## The ClassListDB for the base class
var _classdb: ClassListDB


## Init
func _init(p_base_class: Script, p_objectdb: ObjectDB, p_classdb: ClassListDB) -> void:
	_base_class = p_base_class
	_objectdb = p_objectdb
	_classdb = p_classdb


## Gets the class tree
func get_class_tree() -> Dictionary:
	return _classdb.get_global_class_tree()


## Gets the inheritancemap
func get_inheritance_map() -> Dictionary:
	return _classdb.get_inheritance_map()


## Checks if the given classname is hidden
func is_class_hidden(p_classname: String) -> bool:
	return _classdb.is_class_hidden(p_classname)


## Gets all objects that extend the given classname
func get_objects_by_classname(p_classname: String) -> Array:
	return _objectdb.get_components_by_classname(p_classname)


## Gets an objects classname
func get_object_classname(p_object: Object) -> String:
	return p_object.get_class_name()


## Gets an objects name
func get_object_name(p_object: Object) -> String:
	return p_object.get_uname()


## Checks if p_base extends p_extends
func does_class_extend(p_base: String, p_extends: String) -> bool:
	return _classdb.does_class_inherit(p_base, p_extends)
