extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = get_tree().create_tween()
	tween.tween_property($Black, "modulate:a", 0, 1.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$TotalPower.text = "Total Power Used: " + str(int(Global.TotalPowerUsed)) + "%"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_continue_button_down():
	get_tree().change_scene_to_file("res://scenes/cn_menu.tscn")
