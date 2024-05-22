extends Node3D

@onready var mesh_instance: Draw3D = $MeshInstance

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func draw_box(pos_param: Vector3 = Vector3.ZERO, size: Vector3 = Vector3.ONE, color: Color = Color.ORANGE_RED):
	mesh_instance.cube_up(pos_param, size, color)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
