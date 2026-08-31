extends Control

var id: String = "1234567890"
@export var intensity: String = "?"
@export var intensity_mode = 0 # 0 = shindo/CWA Intensity, 1 or other value = intensity
@export var location: String = ""
@export var datetime: String = ""
#@export var datetime_int = ()
@export var datetime_offset_hr = 0
@export var magnitude: float = 0.0
@export var depth: float = 10.0
@export var source: String = ""

# Intensity colors
var shindo_colors = { # Used by JMA and CWA
	"0": Color("9f9f9f"),
	"1": Color("cfcfcf"),
	"2": Color("3fafff"),
	"3": Color("5fdf8f"),
	"4": Color("f7e757"),
	"5-": Color("ff8f00"),
	"5+": Color("ff4f00"),
	"6-": Color("df0f0f"),
	"6+": Color("af0000"),
	"7": Color("7f007f"),
	"?": Color("000000"),
}
var intensity_colors = {
	"0": Color("9f9f9f"),
	"1": Color("9f9f9f"),
	"2": Color("cfcfcf"),
	"3": Color("5fcfff"),
	"4": Color("3fafff"),
	"5": Color("5fdf8f"),
	"6": Color("f7e757"),
	"7": Color("ff8f00"),
	"8": Color("ff4f00"),
	"9": Color("df0f0f"),
	"10": Color("7f007f"),
	"11": Color("7f007f"),
	"12": Color("7f007f"),
	"?": Color("000000"),
}
var intensity_colors2 = [
	Color("000000"),
	Color("9f9f9f"),
	Color("cfcfcf"),
	Color("5fcfff"),
	Color("3fafff"),
	Color("5fdf8f"),
	Color("f7e757"),
	Color("ff8f00"),
	Color("ff4f00"),
	Color("df0f0f"),
	Color("7f007f"),
	Color("7f007f"),
	Color("7f007f"),
]

func set_Shindo(inten: String):
	# Set an intensity then apply the correct color
	var intensity_str = "?"
	if shindo_colors.has(inten):
		intensity_str = inten
	intensity = intensity_str
	intensity_mode = 0
	
func set_Shindo_color():
	var bgcolor = shindo_colors.get(intensity, Color("000000"))
	$Panel/HBox/Intensity/BgColor.color = bgcolor
	$Panel/HBox/Intensity/value.add_theme_color_override("font_color", IntensityServices.return_correct_font_color(bgcolor))

func set_Intensity(inten: float):
	var intensity_str = "?"
	var intensity_formatted = min(roundi(inten), 12)
	if intensity_formatted >= 0:
		intensity_str = str(intensity_formatted)
	intensity = intensity_str
	intensity_mode = 1
	
	
func set_Intensity_color():
	var bgcolor = intensity_colors.get(intensity, Color("000000"))
	$Panel/HBox/Intensity/BgColor.color = bgcolor
	$Panel/HBox/Intensity/value.add_theme_color_override("font_color", IntensityServices.return_correct_font_color(bgcolor))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Panel/HBox/Intensity/value.text = intensity
	if intensity_mode == 0:
		set_Shindo_color()
	else:
		set_Intensity_color()
	$Panel/HBox/VBox/Location.text = location
	$Panel/HBox/VBox/HBoxContainer/Datetime.text = datetime
	if datetime_offset_hr > 0:
		$Panel/HBox/VBox/HBoxContainer/UTCOffset.text = "(+%s)" % datetime_offset_hr
	elif datetime_offset_hr < 0:
		$Panel/HBox/VBox/HBoxContainer/UTCOffset.text = "(%s)" % datetime_offset_hr
	else:
		$Panel/HBox/VBox/HBoxContainer/UTCOffset.text = ""
	$Panel/HBox/VBox/HBox/Info.text = "M%.1f | %.1f km" % [magnitude, depth]
	$Panel/HBox/VBox/HBox/Source.text = source
