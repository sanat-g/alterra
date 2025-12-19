extends CanvasLayer

@onready var header_label: Label = $Panel/HeaderLabel

func _ready():
	_update_header_from_json()

	var spawner := get_tree().current_scene.get_node_or_null("Spawner")
	if spawner and spawner.has_signal("world_reloaded"):
		spawner.world_reloaded.connect(_update_header_from_json)

func _update_header_from_json():
	var f := FileAccess.open("user://scene.json", FileAccess.READ)
	if f == null:
		f = FileAccess.open("res://scene.json", FileAccess.READ)

	if f == null:
		header_label.text = "Scenario: (missing scene.json)\nRegion: (missing)"
		return

	var text = f.get_as_text()
	var data = JSON.parse_string(text)
	if data == null:
		header_label.text = "Scenario: (invalid JSON)\nRegion: (invalid)"
		return

	var scenario := String(data.get("scenario", ""))
	if scenario == "":
		scenario = "(unknown scenario)"

	var region := ""
	var fr_any = data.get("focus_region")
	if typeof(fr_any) == TYPE_DICTIONARY:
		var fr: Dictionary = fr_any
		var country := String(fr.get("country", ""))
		var admin1 := String(fr.get("admin1", ""))
		var city := String(fr.get("nearest_city", ""))

		if admin1 != "" and country != "":
			region = admin1 + ", " + country
		elif country != "":
			region = country

		if city != "":
			if region != "":
				region += " (near " + city + ")"
			else:
				region = "Near " + city

	if region == "":
		region = "(unknown region)"

	header_label.text = "Scenario: " + scenario + "\nRegion: " + region
	
func refresh() -> void:
	_update_header_from_json()
