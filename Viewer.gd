extends Node3D

const BOUNDING_BOX = preload("res://BoundingBox.tscn")

var mesh_instance: MeshInstance3D = null

@export var accent_color = Color("70bafa")

@export var rotation_degrees_numpad = 5
@export var translation_value_numpad: float = 0.01
@export var offset_boundingbox = Vector3(0, 0, 0)

@onready var loaded_object: Node3D = $LoadedObject
@onready var bounding_box: Node3D = $BoundingBox

@onready var ground_plane: MeshInstance3D = $GroundPlane
@onready var camera_gimbal: CameraGimbal = $CameraGimbal

# UI
@onready var zoom_widget: VBoxContainer = %ZoomWidget
@onready var animation_list_ui: OptionButton = %AnimationListUI
@onready var animation_bar: MarginContainer = %AnimationBar
@onready var animation_play_button: TextureButton = %AnimationPlayButton
@onready var play_bar: HScrollBar = %PlayBar
@onready var loop_mode_button: Button = %LoopModeButton

var animation_player: AnimationPlayer = null
var aabb: AABB
var loaded_model_path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().files_dropped.connect(_on_files_dropped)
	
	# configure zoom UI
	camera_gimbal.connect("zoom_changed", _on_camera_gimbal_zoom_changed)
	zoom_widget.zoom_min(camera_gimbal.zoom_min)
	zoom_widget.zoom_max(camera_gimbal.zoom_max)
	zoom_widget.display_zoom(camera_gimbal.zoom)
	
	var material_path = ""
	var model_path = get_file_parameter()
	if not model_path.is_empty():
		if model_path.to_lower().ends_with(".obj"):
			load_obj(model_path)
		elif model_path.to_lower().ends_with(".glb") or model_path.to_lower().ends_with(".gltf"):
			load_gltf(model_path)
	else:
		set_gimbal_intial_position()
		camera_gimbal.zoom += 1
		#print("HARD CODED OPEN")
		##load_obj("/home/andreas/tmp/Pancake/OBJ/Pancake.obj", "/home/andreas/tmp/Pancake/OBJ/Pancake.mtl")
		##load_obj("/home/andreas/tmp/Spitfire/OBJ/Spitfire.obj")
		## TODO: deliver the binary bundled with this demo file
		#load_gltf("/home/andreas/Games/Assets/3d/gdquest/gobot.glb")
		
		
		#var aabb = calculate_aabb(loaded_object)
		#var wfb = WIREFRAME_BOX.instantiate()
		#loaded_object.add_child(wfb)
		#wfb.wireframe(aabb.position+aabb.size/2.0, aabb.size/2.0)
		
		#focus_camera_on_node(scene_camera, wfb.mesh_instance)
		
		#var aabb_array = collect_aabb(loaded_object)
		#for aabb_sub in aabb_array:
			#var wfb_sub = WIREFRAME_BOX.instantiate()
			#add_child(wfb_sub)
			#wfb_sub.wireframe(aabb_sub.position+aabb_sub.size/2.0, aabb_sub.size/2.0, Color.BLUE)

func _process(delta: float) -> void:
	if animation_player and animation_player.is_playing():
		if animation_player.current_animation_position > 0.5:
			play_bar.value = animation_player.current_animation_position
		else:
			play_bar.value = 0
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed():
		match(event.keycode):
			Key.KEY_KP_0:
				pass
			Key.KEY_KP_1: # Front View
				focus_gimbal_on_aabb(aabb)
				if event.is_ctrl_pressed(): # Back View
					camera_gimbal.gimbal_rotate_x(deg_to_rad(180)) 
				camera_gimbal.gimbal_translate_y(0.01) # just a little to not look into the ground...
			Key.KEY_KP_2: 
				if event.is_ctrl_pressed(): # Translate Scene Down / Camera Up
					camera_gimbal.gimbal_translate_y(translation_value_numpad)
				else: # Rotate Down
					camera_gimbal.gimbal_rotate_y(deg_to_rad(rotation_degrees_numpad))
			Key.KEY_KP_3:
				focus_gimbal_on_aabb(aabb)
				if event.is_ctrl_pressed():
					camera_gimbal.gimbal_rotate_x(deg_to_rad(-90)) # Side View (Face Right)
				else:
					camera_gimbal.gimbal_rotate_x(deg_to_rad(90))  # Side View (Face Left)
				camera_gimbal.gimbal_translate_y(0.01) # just a little to not look into the ground...
			Key.KEY_KP_4:
				if event.is_ctrl_pressed(): # Translate Scene Right / Camera Left
					camera_gimbal.gimbal_translate_x(-translation_value_numpad)
				else:
					camera_gimbal.gimbal_rotate_x(deg_to_rad(-rotation_degrees_numpad))
			Key.KEY_KP_5:
				pass # TODO: toggle perspective orthographic view
			Key.KEY_KP_6: 
				if event.is_ctrl_pressed(): # Translate Scene Right / Camera Left
					camera_gimbal.gimbal_translate_x(translation_value_numpad)
				else: # Rotate Right
					camera_gimbal.gimbal_rotate_x(deg_to_rad(rotation_degrees_numpad))
			Key.KEY_KP_7:
				focus_gimbal_on_aabb(aabb)
				if event.is_ctrl_pressed():
					camera_gimbal.gimbal_rotate_y(deg_to_rad(90)) # Bottom View
				else:
					camera_gimbal.gimbal_rotate_y(deg_to_rad(-90)) # Top View
			Key.KEY_KP_8:
				if event.is_ctrl_pressed(): # Translate Scene Up / Camera Down
					camera_gimbal.gimbal_translate_y(-translation_value_numpad)
				else: # Rotate Up
					camera_gimbal.gimbal_rotate_y(deg_to_rad(-rotation_degrees_numpad)) # just a little to not look into the ground...
				pass
			Key.KEY_KP_9:
				pass
			Key.KEY_KP_SUBTRACT:
				camera_gimbal.zoom += 1
			Key.KEY_KP_ADD:
				camera_gimbal.zoom -= 1
			##### end camera control
			Key.KEY_LEFT:
				models_increment_loader(loaded_model_path, -1)
			Key.KEY_RIGHT:
				models_increment_loader(loaded_model_path, 1)

func models_increment_loader(path: String, increment: int = 0):
	var basedir = path.get_base_dir()
	var filename = path.get_file()
	var dir = DirAccess.open(basedir)
	if dir:
		var files = dir.get_files()
		var model_files: Array[String] = []
		for file_name in files:
			if file_name.to_lower().ends_with(".obj") or file_name.to_lower().ends_with(".glb") or file_name.to_lower().ends_with(".gltf"):
				model_files.push_back(file_name)
				
		if not model_files.is_empty():
			var found_file_num := model_files.find(filename)
			if found_file_num != -1:
				var file_wrap_num := wrapi(found_file_num + increment, 0, model_files.size())
				var next_filename = model_files[file_wrap_num]
				var next_model_path = basedir + "/" + next_filename
				if next_model_path.to_lower().ends_with(".obj"):
					load_obj(next_model_path)
				elif next_model_path.to_lower().ends_with(".glb") or next_model_path.to_lower().ends_with(".gltf"):
					load_gltf(next_model_path)

func list_animations(node: Node) -> Array[String]:
	var animation_array: Array[String] = []
	if node is AnimationPlayer:
		animation_array.append_array(Array(node.get_animation_list()))
		animation_player = node
		play_animation(animation_array.front())
		seek_animation(0)
		animation_player.pause()
		animation_player.connect("animation_finished", _on_animation_finished)
		return animation_array # this could be done as shortcut as it's only allowed to have one AnimationPlayer per GLTF file
				
	for child_node in node.get_children():
		animation_array.append_array(list_animations(child_node))
		
	return animation_array
			
func play_animation(animation: String):
	if animation_player != null:
		animation_player.play(animation)
		animation_player.get_animation(animation).set_loop_mode(loop_mode_button.get_mode())
		var animation_length := animation_player.current_animation_length
		play_bar.value = animation_player.current_animation_position
		play_bar.step = animation_length / 100.0
		play_bar.max_value = animation_length
		
func pause_animation():
	if animation_player != null:
		animation_player.pause()
		
func seek_animation(value: float):
	if animation_player:
		animation_player.seek(value, true)

# TODO: this doesn't work perfect for Bone animations, but it's ok...
func calculate_aabb(node: Node) -> AABB:
	if node is MeshInstance3D:
		aabb = node.mesh.get_aabb()
		
	for child_node in node.get_children():
		# call the function recursive again
		var local_aabb: AABB = calculate_aabb(child_node)
		if "position" in child_node:
			aabb = aabb.merge(local_aabb)
	
	return aabb
	
func collect_aabb(node: Node) -> Array[AABB]:
	var aabb_array: Array[AABB] = []
	if node is MeshInstance3D:
		aabb = node.mesh.get_aabb()
		aabb_array.append(aabb)
		
	for child_node in node.get_children():
		if "position" in child_node:
			# call the function recursive again
			var local_aabb_array = collect_aabb(child_node)
			aabb_array.append_array(local_aabb_array)
	
	return aabb_array

# could be improved but works for the first shot
func focus_gimbal_on_aabb(aabb: AABB, margin = 1.1) -> void:
	var fov = camera_gimbal.fov
	var max_extent =  aabb.get_longest_axis_size()
	var min_distance = (max_extent * margin) / sin(deg_to_rad(fov / 2.0))
	
	camera_gimbal.reset()
	camera_gimbal.zoom = min_distance
	
func set_gimbal_intial_position():
	camera_gimbal.gimbal_translate_y(0.4) # just a little to not look into the ground...
	camera_gimbal.rotate_y(deg_to_rad(20)) # and a little rotation to have a more dynamic camera position
				
	
func clean_old_object():
	animation_play_button.button_pressed = false
	animation_player = null
	animation_list_ui.clear()
	animation_bar.visible = false
	
	camera_gimbal.reset()
	for child in loaded_object.get_children():
		child.free() # in this case don't used queue_free() to ensure it's freed before we continue with the loading
		
	for child in bounding_box.get_children():
		child.free() # in this case don't used queue_free() to ensure it's freed before we continue with the loading
		
		
func load_gltf(model_path: String):
	clean_old_object()
	# Load an existing glTF scene.
	# GLTFState is used by GLTFDocument to store the loaded scene's state.
	# GLTFDocument is the class that handles actually loading glTF data into a Godot node tree,
	# which means it supports glTF features such as lights and cameras.
	var gltf_document_load = GLTFDocument.new()
	var gltf_state_load = GLTFState.new()
	var error = gltf_document_load.append_from_file(model_path, gltf_state_load)
	if error == OK:
		var gltf_scene_root_node = gltf_document_load.generate_scene(gltf_state_load)
		# save pointer to first MeshInstance3D to later overwrite the Material Texture 
		# TODO: more work needed to overwite gltf material!
		#mesh_instance = gltf_scene_root_node.get_child(0)
		loaded_object.add_child(gltf_scene_root_node)
		
		# add all animations from gtlf to the animation dropdown
		var anim_list = list_animations(loaded_object)
		
		if not anim_list.is_empty():
			animation_bar.visible = true
			for anim in anim_list:
				animation_list_ui.add_item(anim)
				
		loaded_model_path = model_path
		DisplayServer.window_set_title(model_path.get_file())
				
		aabb = calculate_aabb(gltf_scene_root_node)
		var wfb = BOUNDING_BOX.instantiate()
		bounding_box.add_child(wfb)
		wfb.draw_box(aabb.position+aabb.size/2.0 + offset_boundingbox, aabb.size/2.0)
		
		focus_gimbal_on_aabb(aabb)
		set_gimbal_intial_position()
	else:
		print("Couldn't load glTF scene (error code: %s)." % error_string(error))

func load_obj(model_path: String, material_path: String = ""):
	clean_old_object()
	var obj_mesh: Mesh = OBJExporter.load_mesh_from_file(model_path, material_path) # second parameter mtl file
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = obj_mesh
	
	aabb = mesh_instance.mesh.get_aabb()
	var wfb = BOUNDING_BOX.instantiate()
	bounding_box.add_child(wfb)
	wfb.draw_box(aabb.position+aabb.size/2.0 + offset_boundingbox, aabb.size/2.0)
	
	focus_gimbal_on_aabb(aabb)
	set_gimbal_intial_position()
	
	loaded_model_path = model_path
	DisplayServer.window_set_title(model_path.get_file())
	
	loaded_object.add_child(mesh_instance)

func apply_texture(mesh_instance_node, texture_path):
	var texture = ImageTexture.new()
	var image = Image.new()
	var error = image.load(texture_path)
	if error == Error.OK:
		texture.set_image(image)
		
		if not mesh_instance_node.material_override:
			var standard_material = StandardMaterial3D.new()
			mesh_instance_node.material_override = standard_material
			
		mesh_instance_node.material_override.albedo_texture = texture
		
func get_file_parameter() -> String:
	var args = Array(OS.get_cmdline_args())
	var file_parameter: String = "" # default is none
	if args != null:
		if args.back() != null:
			var last_arg: String = args.back()
			if not last_arg.begins_with("res://") and not last_arg.begins_with("--"):
				file_parameter = last_arg
	return file_parameter


func _on_camera_gimbal_zoom_changed(value: float):
	zoom_widget.display_zoom(value)

func _on_files_dropped(files):
	var model_path = files[0]
	
	if model_path.to_lower().ends_with(".obj"):
		load_obj(model_path)
	elif model_path.to_lower().ends_with(".glb") or model_path.to_lower().ends_with(".gltf"):
		load_gltf(model_path)
	else:
		# try as texture
		if mesh_instance != null:
			apply_texture(mesh_instance, model_path)

func _on_animation_play_button_toggled(play_request: bool) -> void:
	if play_request:
		play_animation(animation_list_ui.get_item_text(animation_list_ui.get_selected_id()))
	else:
		pause_animation()

func _on_animation_finished(anim_name: StringName):
	animation_play_button.button_pressed = false

func _on_play_bar_scrolling() -> void:
	seek_animation(play_bar.value)

func _on_animation_list_ui_item_selected(index: int) -> void:
	play_animation(animation_list_ui.get_item_text(index))
	seek_animation(0)
	if animation_play_button.button_pressed == false:
		pause_animation()


func _on_loop_mode_button_mode_switched(mode: Animation.LoopMode) -> void:
	if animation_player and animation_player.is_playing():
		animation_player.get_animation(animation_player.current_animation).set_loop_mode(mode)


func _on_axis_button_toggled(toggled_on: bool) -> void:
	$AxisDisplay.visible = toggled_on


func _on_ground_button_toggled(toggled_on: bool) -> void:
	$GroundPlane.visible = toggled_on


func _on_bounding_box_button_toggled(toggled_on: bool) -> void:
	bounding_box.visible = toggled_on


func _on_reset_view_button_pressed() -> void:
	focus_gimbal_on_aabb(aabb)
	set_gimbal_intial_position()
