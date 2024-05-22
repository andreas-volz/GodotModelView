class_name CameraGimbal
extends Node3D

signal zoom_changed(value: float)

@export var mouse_move_sensitivity: float = 500 # bigger number is more sensitive
@export var mouse_rotate_sensitivity: float = 500 # bigger number is more sensitive
@export var mouse_zoom_sensitivity: float = 1 # bigger number is less sensitive

@onready var camera: Camera3D = $InnerGimbal/Camera
@onready var inner_gimbal: Node3D = $InnerGimbal

var zoom: float = 1.0 : set=set_zoom
var zoom_min: float = 1.0
var zoom_max: float = 100.0

var fov : get=get_fov

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += mouse_zoom_sensitivity
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom -= mouse_zoom_sensitivity
				
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			var window_width = int(get_viewport().size.x)
			var window_height = int(get_viewport().size.y)
			#print("size: ", window_width, " / ", window_height)
			
			# ensure the move/rotate system detect that the mouse is warped when cycling over the window border
			if abs(event.relative.x) < window_width / 2.0 and abs(event.relative.y) < window_height / 2.0:
				if event.is_shift_pressed():
					if event.relative.x != 0:
						var t_x = -event.relative.x * (1.0/mouse_move_sensitivity)
						gimbal_translate_x(t_x)
					if event.relative.y != 0:
						var t_y = event.relative.y * (1.0/mouse_move_sensitivity)
						gimbal_translate_y(t_y)
				elif event.is_ctrl_pressed():
					if event.relative.y < 0:
						zoom -= mouse_zoom_sensitivity / 2.0
					if event.relative.y > 0:
						zoom += mouse_zoom_sensitivity / 2.0
				else:
					if event.relative.x != 0:
						var rotation_deg_x = -event.relative.x * (1.0/mouse_rotate_sensitivity)
						gimbal_rotate_x(rotation_deg_x)
					if event.relative.y != 0:
						var rotation_deg_y = -event.relative.y * (1.0/mouse_rotate_sensitivity)
						gimbal_rotate_y(rotation_deg_y)
					
				# warp the mouse pointer if it left the window while move/rotate activity
				var mouse_pos = get_viewport().get_mouse_position()
				var border_warp_sensitivity = 5 # seems to fit for fullscreen
				if mouse_pos.x > window_width - border_warp_sensitivity:
					var new_mouse_pos = Vector2(border_warp_sensitivity, mouse_pos.y)
					Input.warp_mouse(new_mouse_pos)
				elif mouse_pos.x < border_warp_sensitivity:
					var new_mouse_pos = Vector2(window_width-border_warp_sensitivity, mouse_pos.y)
					Input.warp_mouse(new_mouse_pos)
					
				if mouse_pos.y > window_height - border_warp_sensitivity:
					var new_mouse_pos = Vector2(mouse_pos.x, border_warp_sensitivity)
					Input.warp_mouse(new_mouse_pos)
				elif mouse_pos.y < border_warp_sensitivity:
					var new_mouse_pos = Vector2(mouse_pos.x, window_height-border_warp_sensitivity)
					Input.warp_mouse(new_mouse_pos)

func gimbal_translate_x(value: float):
	translate_object_local(Vector3(value, 0, 0))
	
func gimbal_translate_y(value: float):
	inner_gimbal.translate_object_local(Vector3(0, value, 0))

func gimbal_rotate_x(value: float):
	rotate_object_local(Vector3.UP, value)
	
func gimbal_rotate_y(value: float):
	inner_gimbal.rotate_object_local(Vector3.RIGHT, value)

func get_fov():
	return camera.fov

func set_zoom(value: float):
	zoom = clamp(value, zoom_min, zoom_max)
	if zoom > 0.0:
		scale = Vector3(zoom, zoom, zoom)
		zoom_changed.emit(zoom)

func reset():
	zoom = zoom_min
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	inner_gimbal.position = Vector3.ZERO
	inner_gimbal.rotation = Vector3.ZERO
	

		# Ctrl pressed  == zoom
# TODO: support blender keypad controls
