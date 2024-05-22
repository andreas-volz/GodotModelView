extends Node3D

@onready var mesh_instance: Draw3D = $MeshInstance
@onready var axis_length: float = 1000


func _ready() -> void:
	draw_axis()
	
func draw_axis() -> void:
	var x_axis: Array[Vector3] = [
		Vector3(-1*axis_length, 0, 0),
		Vector3(1*axis_length, 0, 0)
	]
	var y_axis: Array[Vector3] = [
		Vector3(0, -1*axis_length, 0),
		Vector3(0, 1*axis_length, 0)
	]
	var z_axis: Array[Vector3] = [
		Vector3(0, 0, -1*axis_length),
		Vector3(0, 0, 1*axis_length)
	]
	
	mesh_instance.draw_line(x_axis, Color.RED)
	#mesh_instance.draw_line(y_axis, Color.GREEN) # this axis never rotates with the current camerar => hide it for now
	mesh_instance.draw_line(z_axis, Color.BLUE)
