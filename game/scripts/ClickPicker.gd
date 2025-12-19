extends Node3D

@onready var label := get_tree().current_scene.get_node("CanvasLayer/Panel/InfoLabel")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick()

func _pick():
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	var to := origin + dir * 1000.0

	var query := PhysicsRayQueryParameters3D.create(origin, to)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)

	if hit.is_empty():
		label.text = "Click an object"
		return

	var collider: Object = hit.get("collider")
	var n: Node = collider as Node
	if n == null:
		label.text = "Clicked: (no collider node)"
		return

	while n != null and not n.has_meta("poi_name"):
		n = n.get_parent()

	if n == null:
		label.text = "Clicked: (no POI data)"
		return

	var name := String(n.get_meta("poi_name"))
	var one := String(n.get_meta("poi_one_liner"))
	label.text = name + "\n" + one
