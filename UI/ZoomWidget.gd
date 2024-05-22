extends VBoxContainer

@onready var zoom_bar: ProgressBar = $ZoomBar
@onready var zoom_level: Label = $ZoomLevel
@onready var hide_timer: Timer = $HideTimer

func zoom_min(value: float):
	zoom_bar.min_value = value

func zoom_max(value: float):
	zoom_bar.max_value = value

func display_zoom(value: float):
	zoom_bar.value = zoom_bar.max_value - value + 1 # +1 as workaround to show a full bar
	var zoom_str = "%.2f" % [value]
	
	zoom_level.text = zoom_str + "m" # tis is currently in meter as the camera is z=1m and scaled
	visible = true
	hide_timer.start()

func _on_hide_timer_timeout() -> void:
	visible = false
