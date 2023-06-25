extends Control

@export var platformer_world_scene : PackedScene
@export var top_down_world_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_button_enter_top_down_pressed() -> void:
	get_tree().change_scene_to_packed(top_down_world_scene)

func _on_button_enter_platformer_pressed() -> void:
	get_tree().change_scene_to_packed(platformer_world_scene)
