extends Node3D

const MIN_POI_DIST: float = 25.0 
const JITTER_TRIES: int = 12
const RANDOM_TRIES: int = 60

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
	for c in get_children():
		c.queue_free()

	var data = _load_scene_json()
	if data == null:
		push_error("Could not load scene.json")
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

func _too_close(x: float, z: float, placed: Array, min_dist: float) -> bool:
	for p in placed:
		var dx: float = x - float(p[0])
		var dz: float = z - float(p[1])
		if dx * dx + dz * dz < min_dist * min_dist:
			return true
	return false

func _find_spaced_pos(
	rng: RandomNumberGenerator,
	preferred_x: float,
	preferred_z: float,
	half_x: float,
	half_z: float,
	placed: Array,
	min_dist: float
) -> Vector2:
	# 1) Try preferred (AI) pos first
	var x: float = clampf(preferred_x, -half_x, half_x)
	var z: float = clampf(preferred_z, -half_z, half_z)
	if not _too_close(x, z, placed, min_dist):
		return Vector2(x, z)

	# 2) Try jitter around preferred
	for _i in range(JITTER_TRIES):
		var jx: float = clampf(x + rng.randf_range(-30.0, 30.0), -half_x, half_x)
		var jz: float = clampf(z + rng.randf_range(-30.0, 30.0), -half_z, half_z)
		if not _too_close(jx, jz, placed, min_dist):
			return Vector2(jx, jz)

	# 3) Try totally random spots
	for _i in range(RANDOM_TRIES):
		var rx: float = rng.randf_range(-half_x, half_x)
		var rz: float = rng.randf_range(-half_z, half_z)
		if not _too_close(rx, rz, placed, min_dist):
			return Vector2(rx, rz)

	# 4) Fallback
	return Vector2(x, z)

func _spawn_pois(data):
	var scene_data = data.get("scene", {})
	if typeof(scene_data) != TYPE_DICTIONARY:
		scene_data = {}
	var scene_dict: Dictionary = scene_data

	var half_x: float = 125.0
	var half_z: float = 125.0
	var size_any = scene_dict.get("size_m", [250, 250])
	if typeof(size_any) == TYPE_ARRAY and size_any.size() >= 2:
		half_x = float(size_any[0]) * 0.5
		half_z = float(size_any[1]) * 0.5

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var placed: Array = []  # stores [x,z]

	var pois = scene_dict.get("pois", [])
	if typeof(pois) != TYPE_ARRAY:
		pois = []

	for poi in pois:
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var poi_dict: Dictionary = poi

		var t: String = String(poi_dict.get("type", "monument")).to_lower()
		var prefab: PackedScene = prefabs.get(t, prefabs["monument"])

		var inst := prefab.instantiate()
		if inst == null or not (inst is Node3D):
			continue
		var inst3d: Node3D = inst as Node3D

		var pos_any = poi_dict.get("pos", [0, 0])
		var x: float = 0.0
		var z: float = 0.0
		if typeof(pos_any) == TYPE_ARRAY and pos_any.size() >= 2:
			x = float(pos_any[0])
			z = float(pos_any[1])

		var v: Vector2 = _find_spaced_pos(rng, x, z, half_x, half_z, placed, MIN_POI_DIST)
		inst3d.position = Vector3(v.x, 0.0, v.y)
		placed.append([v.x, v.y])

		inst3d.set_meta("poi_name", String(poi_dict.get("name", t)))
		inst3d.set_meta("poi_one_liner", String(poi_dict.get("one_liner", "")))
		inst3d.set_meta("poi_because", String(poi_dict.get("because", "")))

		var deps_any = poi_dict.get("depends_on", [])
		var deps: Array = []
		if typeof(deps_any) == TYPE_ARRAY:
			deps = deps_any
		inst3d.set_meta("poi_depends_on", deps)

		add_child(inst3d)
