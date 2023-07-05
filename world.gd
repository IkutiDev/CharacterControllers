extends Node2D

@export var bakcground_color : Color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.set_default_clear_color(bakcground_color)
