extends AnimatedSprite2D

@export var FadeNode : Node2D
@export var Static : Node2D
@export var Sound : AudioStreamPlayer
@export var JumpSound : AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_jump_timer_timeout():
	var FadeTween = self.create_tween()
	FadeTween.tween_property(FadeNode, "modulate:a", 1, 1.5)
	FadeTween.tween_callback(ChangeScene)

func ChangeScene():
	get_tree().change_scene_to_file("res://scenes/endscreen.tscn")

func _on_jump_timer_1_timeout():
	Static.visible = true
	Sound.play()
	JumpSound.stop()
