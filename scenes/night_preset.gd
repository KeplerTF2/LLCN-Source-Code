extends Node

class_name NightPreset

@export var Name : String
@export var AIDiffs : Dictionary = {
	"freddy": 0,
	"bonnie": 0,
	"chica": 0,
	"foxy": 0,
	"fredbear": 0,
	"springtrap": 0,
	"phone_guy": 0,
	"static_guy": 0
}
@export var Challenges : Array = []
@export var Requirements : Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
