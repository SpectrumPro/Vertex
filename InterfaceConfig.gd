## Config
static var config: Dictionary[String, Variant] = {
	"scale_factor": 1,
	"save_ui_on_quit": true,
	"default_ui_panel": UIWindowManager,
	"window_popup_config": {
		#UIMainMenu:				PopupConfig.new("UIMainMenu", ""),
		#UIManifestPicker:		PopupConfig.new("UIManifestPicker"),
		#UIComponentSettings:	PopupConfig.new("UIComponentSettings", "set_component"),
		#UIParameterList:		PopupConfig.new("UIParameterList", "set_fixtures"),
		#UISaveLoad:				PopupConfig.new("UISaveLoad", ""),
		#UISettings:				PopupConfig.new("UISettings", ""),
	}
}
