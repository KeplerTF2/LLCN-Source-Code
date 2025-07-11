extends Node2D

class_name CNCharacter

@export var AnimName : String
@export_multiline var Description : String
var Difficulty : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.play(AnimName)
	$Description/Panel/Label.text = Description
	Update()
	if Global.Mobile:
		$Up.size = Vector2(112,25)
		$Up.position = Vector2(8,8)
		$Down.size = Vector2(112,25)
		$AI.position = Vector2(200,208)
		$Down.modulate.a = 0.5
		$Up.modulate.a = 0.5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func Update():
	$AI.text = str(Difficulty)
	if AnimName != "static_guy":
		$Sprite.visible = Difficulty != 0

func _on_down_button_down():
	Difficulty -= 1
	if Difficulty < 0:
		Difficulty = 20
	Update()
	$Press.play()
	DifficultyChanged.emit(AnimName, self)

func _on_up_button_down():
	Difficulty += 1
	if Difficulty > 20:
		Difficulty = 0
	Update()
	$Press.play()
	DifficultyChanged.emit(AnimName, self)

func _on_area_2d_mouse_entered():
	$Description/Panel.visible = true

func _on_area_2d_mouse_exited():
	$Description/Panel.visible = false

signal DifficultyChanged(AnimName : String, node : CNCharacter)
