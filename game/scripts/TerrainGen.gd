extends Node3D

@export var size: int = 250        
@export var resolution: int = 128
@export var sea_level: float = 0.0

var _mesh_instance: MeshInstance3D


func _ready():
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	regenerate_from_scene_json()

func regenerate_from_scene_json():
	var data = _load_scene_json()
	if data == null:
		return

	var scene = data.get("scene", {})
	var terrain = scene.get("terrain", {})
	var ttype = String(terrain.get("type", "flat"))
	var seed = int(terrain.get("seed", 12345))

	_generate(ttype, seed)

func _load_scene_json():
	var f := FileAccess.open("res://scene.json", FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())

func _generate(ttype: String, seed: int):
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var amp := 0.0
	var freq := 0.015

	match ttype:
		"flat":
			amp = 0.5
		"hilly":
			amp = 8.0
		"forest":
			amp = 2.0
		"coastal":
			amp = 4.0
		"river":
			amp = 3.0
		"urban_ruins":
			amp = 1.0
		_:
			amp = 2.0

	noise.frequency = freq

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half := size * 0.5
	var step := float(size) / float(resolution - 1)

	for z_i in range(resolution - 1):
		for x_i in range(resolution - 1):
			var p00 = _vertex(x_i, z_i, half, step, noise, amp, ttype)
			var p10 = _vertex(x_i + 1, z_i, half, step, noise, amp, ttype)
			var p01 = _vertex(x_i, z_i + 1, half, step, noise, amp, ttype)
			var p11 = _vertex(x_i + 1, z_i + 1, half, step, noise, amp, ttype)

			# two triangles
			st.add_vertex(p00); st.add_vertex(p01); st.add_vertex(p10)
			st.add_vertex(p10); st.add_vertex(p01); st.add_vertex(p11)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_mesh_instance.mesh = mesh

func _vertex(x_i: int, z_i: int, half: float, step: float, noise: FastNoiseLite, amp: float, ttype: String) -> Vector3:
	var x := float(x_i) * step - half
	var z := float(z_i) * step - half

	var h := noise.get_noise_2d(x, z) * amp

	if ttype == "coastal":
		h -= (x / (half)) * 3.0

	if ttype == "river":
		var d: float = absf(x)
		var channel: float = clampf(1.0 - (d / 12.0), 0.0, 1.0) # width ~24m

		h -= channel * 4.0

	return Vector3(x, h, z)
