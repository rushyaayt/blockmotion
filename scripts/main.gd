extends Node3D

const PARTS := {
	"Head": Vector3(0, 2.65, 0),
	"Body": Vector3(0, 1.55, 0),
	"Left Arm": Vector3(-0.85, 1.65, 0),
	"Right Arm": Vector3(0.85, 1.65, 0),
	"Left Leg": Vector3(-0.35, 0.45, 0),
	"Right Leg": Vector3(0.35, 0.45, 0)
}

var selected_part := "Head"
var current_frame := 0
var keyframes: Dictionary = {}
var part_nodes: Dictionary = {}
var status_label: Label
var timeline_label: Label
var inspector_label: Label
var prompt_input: LineEdit
var viewport: SubViewport
var camera: Camera3D

func _ready() -> void:
	_build_viewport()
	_build_editor_ui()
	_build_character()
	_select_part("Head")

func _build_viewport() -> void:
	viewport = SubViewport.new()
	viewport.name = "AnimationViewport"
	viewport.size = Vector2i(860, 600)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#171c2b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#a8b8e8")
	env.ambient_light_energy = 0.75
	environment.environment = env
	viewport.add_child(environment)

	camera = Camera3D.new()
	camera.position = Vector3(5.8, 3.7, 7.6)
	camera.look_at_from_position(camera.position, Vector3(0, 1.45, 0))
	viewport.add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, -25, 0)
	key_light.light_energy = 1.2
	viewport.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-3, 4, 4)
	fill_light.light_color = Color("#8bb8ff")
	fill_light.omni_range = 12.0
	fill_light.light_energy = 2.0
	viewport.add_child(fill_light)

	var display := TextureRect.new()
	display.name = "ViewportDisplay"
	display.texture = viewport.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(display)
	move_child(display, 0)

func _build_editor_ui() -> void:
	var overlay := CanvasLayer.new()
	add_child(overlay)

	var top_bar := ColorRect.new()
	top_bar.color = Color("#20283b")
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(1280, 58)
	overlay.add_child(top_bar)

	var title := Label.new()
	title.text = "  BLOCKMOTION"
	title.position = Vector2(18, 12)
	title.add_theme_font_size_override("font_size", 22)
	top_bar.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Minecraft animation editor"
	subtitle.position = Vector2(195, 19)
	subtitle.modulate = Color("#9aa7c4")
	top_bar.add_child(subtitle)

	var save_button := Button.new()
	save_button.text = "Save project"
	save_button.position = Vector2(1015, 10)
	save_button.size = Vector2(112, 36)
	save_button.pressed.connect(_save_project)
	top_bar.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "Load"
	load_button.position = Vector2(1136, 10)
	load_button.size = Vector2(78, 36)
	load_button.pressed.connect(_load_project)
	top_bar.add_child(load_button)

	var right_panel := ColorRect.new()
	right_panel.color = Color("#20283b")
	right_panel.position = Vector2(940, 58)
	right_panel.size = Vector2(340, 662)
	overlay.add_child(right_panel)

	var inspector_title := Label.new()
	inspector_title.text = "INSPECTOR"
	inspector_title.position = Vector2(24, 78)
	inspector_title.add_theme_color_override("font_color", Color("#91a8d8"))
	right_panel.add_child(inspector_title)

	inspector_label = Label.new()
	inspector_label.position = Vector2(24, 116)
	inspector_label.size = Vector2(285, 220)
	inspector_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_panel.add_child(inspector_label)

	var add_key := Button.new()
	add_key.text = "Add keyframe  (K)"
	add_key.position = Vector2(24, 300)
	add_key.size = Vector2(150, 38)
	add_key.pressed.connect(_add_keyframe)
	right_panel.add_child(add_key)

	var reset := Button.new()
	reset.text = "Reset pose"
	reset.position = Vector2(184, 300)
	reset.size = Vector2(120, 38)
	reset.pressed.connect(_reset_pose)
	right_panel.add_child(reset)

	var prompt_title := Label.new()
	prompt_title.text = "PROMPT ANIMATION"
	prompt_title.position = Vector2(24, 350)
	prompt_title.add_theme_color_override("font_color", Color("#91a8d8"))
	right_panel.add_child(prompt_title)

	prompt_input = LineEdit.new()
	prompt_input.placeholder_text = "e.g. make the character wave"
	prompt_input.position = Vector2(24, 378)
	prompt_input.size = Vector2(280, 36)
	prompt_input.text_submitted.connect(_generate_from_prompt)
	right_panel.add_child(prompt_input)

	var generate_button := Button.new()
	generate_button.text = "Generate animation"
	generate_button.position = Vector2(24, 420)
	generate_button.size = Vector2(280, 38)
	generate_button.pressed.connect(func() -> void: _generate_from_prompt(prompt_input.text))
	right_panel.add_child(generate_button)

	var parts_title := Label.new()
	parts_title.text = "RIG PARTS"
	parts_title.position = Vector2(24, 476)
	parts_title.add_theme_color_override("font_color", Color("#91a8d8"))
	right_panel.add_child(parts_title)

	var y := 510
	for part_name in PARTS:
		var button := Button.new()
		button.text = part_name
		button.position = Vector2(24, y)
		button.size = Vector2(280, 30)
		button.pressed.connect(_select_part.bind(part_name))
		right_panel.add_child(button)
		y += 32

	var timeline_panel := ColorRect.new()
	timeline_panel.color = Color("#151a29")
	timeline_panel.position = Vector2(0, 600)
	timeline_panel.size = Vector2(940, 120)
	overlay.add_child(timeline_panel)

	var timeline_title := Label.new()
	timeline_title.text = "TIMELINE"
	timeline_title.position = Vector2(24, 616)
	timeline_title.add_theme_color_override("font_color", Color("#91a8d8"))
	timeline_panel.add_child(timeline_title)

	timeline_label = Label.new()
	timeline_label.position = Vector2(24, 650)
	timeline_label.size = Vector2(880, 50)
	timeline_label.text = "Frame 0    |    1    2    3    4    5    6    7    8    9    10    11    12"
	timeline_panel.add_child(timeline_label)

	status_label = Label.new()
	status_label.position = Vector2(24, 690)
	status_label.modulate = Color("#7c8aa8")
	overlay.add_child(status_label)

func _build_character() -> void:
	var root := Node3D.new()
	root.name = "CharacterRig"
	viewport.add_child(root)

	for part_name in PARTS:
		var mesh_instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = _part_size(part_name)
		mesh_instance.mesh = mesh
		mesh_instance.position = PARTS[part_name]
		mesh_instance.name = part_name
		mesh_instance.material_override = _material_for(part_name)
		root.add_child(mesh_instance)
		part_nodes[part_name] = mesh_instance

	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(8, 0.15, 8)
	floor.mesh = floor_mesh
	floor.position = Vector3(0, -0.12, 0)
	floor.material_override = _material(Color("#293149"))
	viewport.add_child(floor)

func _part_size(part_name: String) -> Vector3:
	if part_name == "Head":
		return Vector3(1.35, 1.35, 1.35)
	if part_name == "Body":
		return Vector3(1.25, 1.7, 0.7)
	if part_name.contains("Arm"):
		return Vector3(0.45, 1.55, 0.55)
	return Vector3(0.5, 1.45, 0.6)

func _material_for(part_name: String) -> StandardMaterial3D:
	var color := Color("#4e79c7")
	if part_name == "Head":
		color = Color("#e7b27e")
	elif part_name.contains("Arm") or part_name.contains("Leg"):
		color = Color("#375a9c")
	return _material(color)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material

func _select_part(part_name: String) -> void:
	selected_part = part_name
	for name in part_nodes:
		var node: MeshInstance3D = part_nodes[name]
		node.material_override = _material(Color("#f6c453") if name == part_name else _base_color(name))
	inspector_label.text = "%s\n\nPosition\n  %s\n\nRotation\n  %s\n\nClick 'Add keyframe' to capture this pose." % [
		part_name, str(part_nodes[part_name].position), str(part_nodes[part_name].rotation_degrees)
	]

func _base_color(part_name: String) -> Color:
	if part_name == "Head":
		return Color("#e7b27e")
	if part_name.contains("Arm") or part_name.contains("Leg"):
		return Color("#375a9c")
	return Color("#4e79c7")

func _add_keyframe() -> void:
	if not keyframes.has(current_frame):
		keyframes[current_frame] = {}
	keyframes[current_frame][selected_part] = part_nodes[selected_part].rotation_degrees
	_update_timeline()
	status_label.text = "Keyframe added for %s at frame %d" % [selected_part, current_frame]

func _update_timeline() -> void:
	var marker := ""
	for frame in range(13):
		marker += ("#" if keyframes.has(frame) else ".") + " "
	timeline_label.text = "Frame %d    %s" % [current_frame, marker]

func _generate_from_prompt(prompt: String) -> void:
	var normalized := prompt.strip_edges().to_lower()
	if normalized.is_empty():
		status_label.text = "Enter a prompt such as 'make the character wave'"
		return
	var animation_name := ""
	if "wave" in normalized:
		animation_name = "wave"
		_make_wave_animation()
	elif "walk" in normalized or "run" in normalized:
		animation_name = "walk"
		_make_walk_animation()
	elif "jump" in normalized:
		animation_name = "jump"
		_make_jump_animation()
	elif "dance" in normalized:
		animation_name = "dance"
		_make_dance_animation()
	else:
		status_label.text = "I don't know that animation yet. Try: wave, walk, jump, or dance."
		return
	current_frame = 0
	_apply_keyframe_pose(0)
	_update_timeline()
	status_label.text = "Generated '%s' animation from prompt" % animation_name

func _begin_generated_animation() -> void:
	keyframes.clear()
	_reset_all_pose()

func _set_generated_frame(frame: int, poses: Dictionary) -> void:
	keyframes[frame] = poses

func _make_wave_animation() -> void:
	_begin_generated_animation()
	_set_generated_frame(0, {"Right Arm": Vector3.ZERO})
	_set_generated_frame(8, {"Right Arm": Vector3(-25, 0, -55), "Head": Vector3(0, 0, 8)})
	_set_generated_frame(16, {"Right Arm": Vector3(25, 0, -55), "Head": Vector3(0, 0, -8)})
	_set_generated_frame(24, {"Right Arm": Vector3(-25, 0, -55), "Head": Vector3(0, 0, 8)})
	_set_generated_frame(32, {"Right Arm": Vector3.ZERO})

func _make_walk_animation() -> void:
	_begin_generated_animation()
	_set_generated_frame(0, {"Left Leg": Vector3(-28, 0, 0), "Right Leg": Vector3(28, 0, 0), "Left Arm": Vector3(28, 0, 0), "Right Arm": Vector3(-28, 0, 0)})
	_set_generated_frame(8, {"Left Leg": Vector3(28, 0, 0), "Right Leg": Vector3(-28, 0, 0), "Left Arm": Vector3(-28, 0, 0), "Right Arm": Vector3(28, 0, 0)})
	_set_generated_frame(16, {"Left Leg": Vector3(-28, 0, 0), "Right Leg": Vector3(28, 0, 0), "Left Arm": Vector3(28, 0, 0), "Right Arm": Vector3(-28, 0, 0)})

func _make_jump_animation() -> void:
	_begin_generated_animation()
	_set_generated_frame(0, {"Left Leg": Vector3.ZERO, "Right Leg": Vector3.ZERO})
	_set_generated_frame(8, {"Left Leg": Vector3(-18, 0, 0), "Right Leg": Vector3(18, 0, 0), "Left Arm": Vector3(-35, 0, 0), "Right Arm": Vector3(-35, 0, 0)})
	_set_generated_frame(16, {"Left Leg": Vector3(-18, 0, 0), "Right Leg": Vector3(18, 0, 0), "Left Arm": Vector3(-35, 0, 0), "Right Arm": Vector3(-35, 0, 0)})
	_set_generated_frame(24, {"Left Leg": Vector3.ZERO, "Right Leg": Vector3.ZERO, "Left Arm": Vector3.ZERO, "Right Arm": Vector3.ZERO})

func _make_dance_animation() -> void:
	_begin_generated_animation()
	_set_generated_frame(0, {"Left Arm": Vector3(0, 0, -35), "Right Arm": Vector3(0, 0, 35), "Head": Vector3(0, 0, -10)})
	_set_generated_frame(8, {"Left Arm": Vector3(0, 0, 35), "Right Arm": Vector3(0, 0, -35), "Head": Vector3(0, 0, 10)})
	_set_generated_frame(16, {"Left Arm": Vector3(0, 0, -35), "Right Arm": Vector3(0, 0, 35), "Head": Vector3(0, 0, -10)})

func _reset_all_pose() -> void:
	for node in part_nodes.values():
		node.rotation = Vector3.ZERO

func _apply_keyframe_pose(frame: int) -> void:
	_reset_all_pose()
	if not keyframes.has(frame):
		return
	for part_name in keyframes[frame]:
		if part_nodes.has(part_name):
			part_nodes[part_name].rotation_degrees = keyframes[frame][part_name]
	_select_part(selected_part)

func _reset_pose() -> void:
	_reset_all_pose()
	_select_part(selected_part)
	status_label.text = "Pose reset"

func _save_project() -> void:
	var data := {"current_frame": current_frame, "keyframes": keyframes}
	var file := FileAccess.open("user://blockmotion_project.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	status_label.text = "Project saved to user://blockmotion_project.json"

func _load_project() -> void:
	if not FileAccess.file_exists("user://blockmotion_project.json"):
		status_label.text = "No saved project found yet"
		return
	var file := FileAccess.open("user://blockmotion_project.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		current_frame = int(data.get("current_frame", 0))
		keyframes = data.get("keyframes", {})
		_update_timeline()
		status_label.text = "Project loaded"

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			_add_keyframe()
		elif event.keycode == KEY_LEFT:
			current_frame = maxi(current_frame - 1, 0)
			_apply_keyframe_pose(current_frame)
			_update_timeline()
		elif event.keycode == KEY_RIGHT:
			current_frame = mini(current_frame + 1, 120)
			_apply_keyframe_pose(current_frame)
			_update_timeline()
