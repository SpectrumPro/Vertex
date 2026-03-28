## All user defined UIPanels
static var panels: Dictionary[String, PackedScene]

## All user defined UIPanels
static var popups: Dictionary[String, PackedScene]

## All user defined UIPanels
static var components: Dictionary[String, PackedScene]

## All user defined UIPanels
static var data_inputs: Dictionary[Data.Type, Variant] = {
	Data.Type.PACKEDSCENE: {
		Data.Sub.Type.PACKEDSCENE_UIPANEL:		load(CoreUIDB._d("DataInputUIPanel")),
	}
}

## All user defined UIPanels
static var class_icons: Dictionary[String, PackedScene]

## Categorys of the user defined panels
static var panels_by_category: Dictionary[String, Dictionary]

## Config
static var config: Dictionary[String, Variant] = {
	"panels": panels,
	"popups": popups,
	"components": components,
	"data_inputs": data_inputs,
	"class_icons": class_icons,
	"panels_by_category": panels_by_category
}
