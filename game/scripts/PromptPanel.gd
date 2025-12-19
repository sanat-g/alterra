extends Panel

@export var terrain_path: NodePath
@export var python_cmd: String = "python3"
@export var generator_abs_path: String = "/Users/sanatguduru/Desktop/AltWorldMVP/ai/generate_scene.py"

@export var spawner_path: NodePath
@export var header_path: NodePath

@onready var prompt_edit: LineEdit = $PromptLineEdit
@onready var status_label: Label = $StatusLabel
@onready var btn: Button = $GenerateButton

var busy := false

func _ready() -> void:
	btn.pressed.connect(_on_generate_pressed)
	prompt_edit.text_submitted.connect(func(_t): _on_generate_pressed())
	status_label.text = "Type a prompt and press Generate."

func _on_generate_pressed() -> void:
	if busy:
		return

	var scenario := prompt_edit.text.strip_edges()
	if scenario == "":
		status_label.text = "Enter a prompt first."
		return

	busy = true
	btn.disabled = true
	status_label.text = "Generating…"

	var output: Array = []
	var exit_code := OS.execute(python_cmd, PackedStringArray([generator_abs_path, scenario]), output, true)

	if exit_code != 0:
		status_label.text = "Generation failed. Check Output."
		print("Python output:\n", "\n".join(output))
		busy = false
		btn.disabled = false
		return

	status_label.text = "Generated! Reloading…"

	var spawner = get_node_or_null(spawner_path)
	if spawner != null and spawner.has_method("reload_from_json"):
		spawner.call("reload_from_json")

	var terrain = get_node_or_null(terrain_path)
	if terrain != null and terrain.has_method("regenerate_from_scene_json"):
		terrain.call("regenerate_from_scene_json")

	var header = get_node_or_null(header_path)
	if header != null and header.has_method("refresh"):
		header.call("refresh")

	status_label.text = "Done."
	busy = false
	btn.disabled = false
