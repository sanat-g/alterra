extends Node3D

var prefabs := {
	"temple": preload("res://scenes/poi/temple.tscn"),
	"lab": preload("res://scenes/poi/lab.tscn"),
	"factory": preload("res://scenes/poi/factory.tscn"),
	"nest": preload("res://scenes/poi/nest.tscn"),
	"monument": preload("res://scenes/poi/monument.tscn")
}

func _ready():
	reload_from_json()

func reload_from_json():
	# Clear only POIs spawned under this node
	for c in get_children():
		c.queue_free()

	var data = _load_scene_json()
	if data == null:
		push_error("Could not load res://scene.json")
		return

	_spawn_pois(data)

func _load_scene_json():
	var paths := ["user://scene.json", "res://scene.json"]

	for p in paths:
		if FileAccess.file_exists(p):
			var f := FileAccess.open(p, FileAccess.READ)
			if f != null:
				var text := f.get_as_text()
				var data = JSON.parse_string(text)
				if typeof(data) == TYPE_DICTIONARY:
					return data

	return null

func _spawn_pois(data):
	# Don't use := here (Variant typing)
	var scene_data = data.get("scene", {})
	if typeof(scene_data) != TYPE_DICTIONARY:
		scene_data = {}

	var pois = scene_data.get("pois", [])
	if typeof(pois) != TYPE_ARRAY:
		pois = []

	for poi in pois:
		if typeof(poi) != TYPE_DICTIONARY:
			continue

		var t := String(poi.get("type", "monument")).to_lower()
		var prefab: PackedScene = prefabs.get(t, prefabs["monument"])

		var inst: Node3D = prefab.instantiate() as Node3D
		if inst == null:
			continue

		var pos = poi.get("pos", [0, 0])
		if typeof(pos) != TYPE_ARRAY or pos.size() < 2:
			pos = [0, 0]

		inst.position = Vector3(float(pos[0]), 0.0, float(pos[1]))

		# Existing fields
		inst.set_meta("poi_name", String(poi.get("name", t)))
		inst.set_meta("poi_one_liner", String(poi.get("one_liner", "")))

		# New Step 2 fields
		inst.set_meta("poi_because", String(poi.get("because", "")))

		var deps = poi.get("depends_on", [])
		if typeof(deps) != TYPE_ARRAY:
			deps = []
		inst.set_meta("poi_depends_on", deps)

		add_child(inst)
