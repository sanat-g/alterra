extends Node3D

@export var max_distance: float = 1000.0
@export var info_label_path: NodePath

@onready var info_label: Label = get_node_or_null(info_label_path) as Label

func _ready() -> void:
	if info_label == null:
		push_warning("POISelector: info_label_path is not set or not a Label.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_pick()

func _try_pick() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_from: Vector3 = cam.project_ray_origin(mouse_pos)
	var ray_to: Vector3 = ray_from + cam.project_ray_normal(mouse_pos) * max_distance

	var world: World3D = get_viewport().get_world_3d()
	if world == null:
		return

	var space_state: PhysicsDirectSpaceState3D = world.direct_space_state

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hit: Dictionary = space_state.intersect_ray(query)

	if hit.is_empty():
		if info_label != null:
			info_label.text = "Click an object"
		return

	var collider_obj: Object = hit.get("collider", null)
	if collider_obj == null:
		return

	var meta_node: Node = _find_meta_owner(collider_obj)
	if meta_node == null:
		if info_label != null:
			info_label.text = "Clicked (no POI meta found)"
		return

	var name_text: String = String(meta_node.get_meta("poi_name", ""))
	var line_text: String = String(meta_node.get_meta("poi_one_liner", ""))

	if info_label != null:
		info_label.text = name_text + "\n" + line_text

func _find_meta_owner(collider_obj: Object) -> Node:
	if not (collider_obj is Node):
		return null

	var n: Node = collider_obj as Node

	var steps := 0
	while n != null and steps < 10:
		if n.has_meta("poi_name"):
			return n
		n = n.get_parent()
		steps += 1

	return null
