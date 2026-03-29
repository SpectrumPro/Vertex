#class_name DataConfig extends Object


## Class to store SubType keys
class SubType:
	enum Type {
		NULL,						## No Type
		OBJECT_UIPANEL,				## A UIPanel instance
		PACKEDSCENE_UIPANEL,		## A UIPanel
	}


## Config for Data
static var config: Dictionary[String, Variant] = {
	"custom_type_to_string_method": custom_type_to_string,
	"get_object_name_signal_method": get_object_name_changed_signal,
}


## Converts a custom data type to a string, with a human readable name
@warning_ignore("unused_parameter")
static func custom_type_to_string(p_variant: Variant, p_orignal_type: Data.Type) -> Variant:
	## return a String to override default convertion
	# return "Value"

	## else return false to use default convertion
	return false


## Returns the signal emitted when the name of an object is changed
static func get_object_name_changed_signal(p_module: SettingsModule) -> Variant:
	var object: Variant = p_module.get_getter().call()
	
	## return Signal() if the object type is invalid, or has no name signal
	if typeof(object) != TYPE_OBJECT or not is_instance_valid(object):
		return Signal()
	
	## check object type and return correct signal
	if object is UIBase:
		return object.name_changed
	
	## else return false to use default 
	return false
