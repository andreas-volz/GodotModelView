extends Button

signal mode_switched(mode:Animation.LoopMode)

@export var accent_color = Color("70bafa")

const LOOP = preload("res://Assets/icons/Loop.svg")
const PING_PONG_LOOP = preload("res://Assets/icons/PingPongLoop.svg")

var mode:Animation.LoopMode = Animation.LoopMode.LOOP_NONE : set=set_mode,get=get_mode

func switch_mode():
	match(mode):
		Animation.LoopMode.LOOP_NONE:
			mode = Animation.LoopMode.LOOP_LINEAR
		Animation.LoopMode.LOOP_LINEAR:
			mode = Animation.LoopMode.LOOP_PINGPONG
		Animation.LoopMode.LOOP_PINGPONG:
			mode = Animation.LoopMode.LOOP_NONE
	mode_switched.emit(mode)

func set_mode(mode_param: Animation.LoopMode):
	mode = mode_param
	match(mode):
		Animation.LoopMode.LOOP_NONE:
			icon = LOOP
			add_theme_color_override("icon_normal_color", Color.WHITE)
			add_theme_color_override("icon_hover_color", Color.WHITE)
			add_theme_color_override("icon_pressed_color", Color.WHITE)
		Animation.LoopMode.LOOP_LINEAR:
			icon = LOOP
			add_theme_color_override("icon_normal_color", accent_color)
			add_theme_color_override("icon_hover_color", accent_color)
			add_theme_color_override("icon_pressed_color", accent_color)
		Animation.LoopMode.LOOP_PINGPONG:
			icon = PING_PONG_LOOP
			add_theme_color_override("icon_normal_color", accent_color)
			add_theme_color_override("icon_hover_color", accent_color)
			add_theme_color_override("icon_pressed_color", accent_color)

func get_mode() -> Animation.LoopMode:
	return mode


func _on_pressed() -> void:
	switch_mode()
